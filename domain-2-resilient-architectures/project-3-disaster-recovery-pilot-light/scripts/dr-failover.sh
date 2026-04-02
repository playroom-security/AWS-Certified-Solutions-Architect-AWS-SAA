#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 2.3 - DR Failover Runbook
# Run this when primary region (us-east-1) is unavailable
# Update the variables below before running
# ─────────────────────────────────────────────────────────────────────────────

PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"
RDS_REPLICA_ID="saa-dr-replica"
DR_ASG_NAME="saa-dr-asg"
DR_DESIRED_CAPACITY=2
HEALTH_CHECK_ID="your-route53-health-check-id"

echo "============================================================"
echo "  DR FAILOVER RUNBOOK - SAA Study Project 2.3"
echo "  DR Region: $DR_REGION"
echo "  $(date)"
echo "============================================================"
echo ""
echo "⚠️  CONFIRM: Primary region $PRIMARY_REGION is confirmed down"
read -p "Type 'FAILOVER' to proceed: " CONFIRM
if [ "$CONFIRM" != "FAILOVER" ]; then
  echo "Failover cancelled."
  exit 0
fi

FAILOVER_START=$(date +%s)

# ─── STEP 1: Promote RDS Read Replica ────────────────────────────────────────
echo ""
echo "[STEP 1/4] Promoting RDS read replica to standalone instance..."
aws rds promote-read-replica \
  --db-instance-identifier "$RDS_REPLICA_ID" \
  --region "$DR_REGION"

echo "Waiting for RDS promotion to complete (this takes 5–10 minutes)..."
aws rds wait db-instance-available \
  --db-instance-identifier "$RDS_REPLICA_ID" \
  --region "$DR_REGION"

NEW_RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$RDS_REPLICA_ID" \
  --region "$DR_REGION" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

echo "✅ RDS promoted. New endpoint: $NEW_RDS_ENDPOINT"

# ─── STEP 2: Scale Up DR Auto Scaling Group ──────────────────────────────────
echo ""
echo "[STEP 2/4] Scaling up DR Auto Scaling Group to $DR_DESIRED_CAPACITY instances..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$DR_ASG_NAME" \
  --desired-capacity "$DR_DESIRED_CAPACITY" \
  --min-size 2 \
  --region "$DR_REGION"

echo "Waiting for EC2 instances to be healthy in DR..."
sleep 120
echo "✅ ASG scaled up"

# ─── STEP 3: Verify DR ALB Health ────────────────────────────────────────────
echo ""
echo "[STEP 3/4] Checking DR ALB target health..."
DR_TG_ARN=$(aws elbv2 describe-target-groups \
  --names "saa-dr-targets" \
  --region "$DR_REGION" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

HEALTHY=$(aws elbv2 describe-target-health \
  --target-group-arn "$DR_TG_ARN" \
  --region "$DR_REGION" \
  --query "TargetHealthDescriptions[?TargetHealth.State=='healthy'] | length(@)" \
  --output text)

echo "✅ Healthy targets in DR: $HEALTHY"

# ─── STEP 4: Confirm Route 53 Failover ───────────────────────────────────────
echo ""
echo "[STEP 4/4] Verifying Route 53 has failed over..."
echo "Check Route 53 health check status manually in console:"
echo "https://console.aws.amazon.com/route53/healthchecks/home#/$HEALTH_CHECK_ID"

FAILOVER_END=$(date +%s)
RTO_SECONDS=$((FAILOVER_END - FAILOVER_START))
RTO_MINUTES=$((RTO_SECONDS / 60))

echo ""
echo "============================================================"
echo "  ✅ FAILOVER COMPLETE"
echo "  RTO achieved: ~${RTO_MINUTES} minutes (${RTO_SECONDS} seconds)"
echo "  New RDS endpoint: $NEW_RDS_ENDPOINT"
echo ""
echo "  POST-FAILOVER TASKS:"
echo "  1. Notify stakeholders"
echo "  2. Monitor DR region CloudWatch dashboards"
echo "  3. Plan failback to primary once primary is recovered"
echo "  4. DO NOT run dr-failback.sh until primary is fully restored"
echo "============================================================"
