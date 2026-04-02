#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 4.1 - Spot Instance Interruption Handler
# Run this as a background service on all Spot Instances.
# Polls the EC2 instance metadata for a termination notice every 5 seconds.
# When a 2-minute warning is received, performs graceful shutdown tasks.
#
# Setup: Add to /etc/systemd/system/spot-handler.service
# ─────────────────────────────────────────────────────────────────────────────

# Configuration — update these before deploying
S3_CHECKPOINT_BUCKET="your-checkpoint-bucket"
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:ACCOUNT_ID:spot-alerts"
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/saa-tg/xxxx"
WORK_DIR="/var/app/current"

# Get IMDSv2 token (required for modern EC2 metadata access)
get_imds_token() {
  curl -s -X PUT \
    "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60"
}

# Get instance metadata value
get_metadata() {
  local TOKEN=$1
  local PATH=$2
  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$PATH" 2>/dev/null
}

echo "[spot-handler] Starting Spot interruption monitor..."

while true; do
  TOKEN=$(get_imds_token)
  INSTANCE_ID=$(get_metadata "$TOKEN" "instance-id")
  AZ=$(get_metadata "$TOKEN" "placement/availability-zone")

  # Check for termination notice
  # This endpoint returns the termination time when AWS sends a 2-min warning
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/spot/termination-time")

  if [ "$HTTP_CODE" = "200" ]; then
    TERM_TIME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      "http://169.254.169.254/latest/meta-data/spot/termination-time")

    echo "[spot-handler] ⚠️  INTERRUPTION NOTICE RECEIVED at $(date)"
    echo "[spot-handler] Instance $INSTANCE_ID in $AZ will terminate at $TERM_TIME"
    echo "[spot-handler] Starting graceful shutdown sequence..."

    # ── STEP 1: Deregister from Load Balancer ────────────────────────────────
    echo "[spot-handler] [1/4] Deregistering from ALB target group..."
    aws elbv2 deregister-targets \
      --target-group-arn "$TARGET_GROUP_ARN" \
      --targets "Id=$INSTANCE_ID" \
      --region us-east-1 2>/dev/null
    echo "[spot-handler] ✅ Deregistered from ALB"

    # ── STEP 2: Save Work in Progress to S3 ──────────────────────────────────
    echo "[spot-handler] [2/4] Checkpointing work to S3..."
    if [ -d "$WORK_DIR" ]; then
      CHECKPOINT_KEY="checkpoints/$INSTANCE_ID/$(date +%Y%m%d-%H%M%S)/"
      aws s3 sync "$WORK_DIR" "s3://$S3_CHECKPOINT_BUCKET/$CHECKPOINT_KEY" \
        --quiet 2>/dev/null
      echo "[spot-handler] ✅ Work checkpointed to s3://$S3_CHECKPOINT_BUCKET/$CHECKPOINT_KEY"
    fi

    # ── STEP 3: Send Alert Notification ──────────────────────────────────────
    echo "[spot-handler] [3/4] Sending SNS alert..."
    aws sns publish \
      --topic-arn "$SNS_TOPIC_ARN" \
      --subject "Spot Interruption: $INSTANCE_ID" \
      --message "Spot instance $INSTANCE_ID ($AZ) is being terminated at $TERM_TIME. Work checkpointed to S3." \
      --region us-east-1 2>/dev/null
    echo "[spot-handler] ✅ Alert sent"

    # ── STEP 4: Graceful App Shutdown ────────────────────────────────────────
    echo "[spot-handler] [4/4] Stopping application gracefully..."
    systemctl stop myapp 2>/dev/null || true

    echo "[spot-handler] ✅ Graceful shutdown complete. Instance terminating in ~90 seconds."
    exit 0
  fi

  # No interruption — sleep and check again
  sleep 5
done
