#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 2.3 - DR Failback Runbook
# Run this AFTER the primary region (us-east-1) has been fully recovered
# and verified. Returns traffic from DR (us-west-2) back to primary.
#
# WARNING: Do NOT run this until primary is confirmed healthy.
# ─────────────────────────────────────────────────────────────────────────────

PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"
PRIMARY_ASG_NAME="SAA-Primary-ASG"
DR_ASG_NAME="saa-dr-asg"
DR_RDS_ID="saa-dr-replica"           # The promoted standalone instance in DR
PRIMARY_RDS_ID="saa-primary-mysql"   # The recovered primary instance

echo "============================================================"
echo "  DR FAILBACK RUNBOOK - SAA Study Project 2.3"
echo "  Returning traffic: us-west-2 → us-east-1 (PRIMARY)"
echo "  $(date)"
echo "============================================================"
echo ""
echo "⚠️  PRE-FLIGHT CHECKLIST — confirm ALL before proceeding:"
echo "  [ ] Primary region EC2 instances are healthy"
echo "  [ ] Primary RDS instance is running and accepting connections"
echo "  [ ] Primary ALB health checks are passing"
echo "  [ ] Data has been synced from DR RDS back to Primary RDS"
echo ""
read -p "Type 'FAILBACK' to proceed: " CONFIRM
if [ "$CONFIRM" != "FAILBACK" ]; then
  echo "Failback cancelled."
  exit 0
fi

FAILBACK_START=$(date +%s)

# ─── STEP 1: Verify Primary Region Health ────────────────────────────────────
echo ""
echo "[STEP 1/5] Verifying primary region ASG health..."
PRIMARY_HEALTHY=$(aws autoscaling describe-auto-scaling-instances \
  --region "$PRIMARY_REGION" \
  --query "AutoScalingInstances[?AutoScalingGroupName=='$PRIMARY_ASG_NAME' && HealthStatus=='Healthy'] | length(@)" \
  --output text 2>/dev/null || echo "0")

if [ "$PRIMARY_HEALTHY" -lt "2" ]; then
  echo "❌ ERROR: Only $PRIMARY_HEALTHY healthy instance(s) in primary ASG."
  echo "   Wait for primary to fully recover before failing back."
  exit 1
fi
echo "✅ Primary ASG has $PRIMARY_HEALTHY healthy instances"

# ─── STEP 2: Re-enable Route 53 Health Check on Primary ──────────────────────
echo ""
echo "[STEP 2/5] Route 53 health check should automatically detect primary recovery."
echo "  Check the health check status in the console:"
echo "  https://console.aws.amazon.com/route53/healthchecks"
echo ""
echo "  Once the primary health check shows HEALTHY, Route 53 failover"
echo "  routing will automatically shift traffic back to primary."
echo "  (No manual DNS change needed for Failover routing policy)"
read -p "  Press ENTER once Route 53 health check shows HEALTHY for primary..."

# ─── STEP 3: Scale Down DR ASG (return to pilot light state) ────────────────
echo ""
echo "[STEP 3/5] Scaling DR ASG back to 0 (restoring pilot light state)..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$DR_ASG_NAME" \
  --desired-capacity 0 \
  --min-size 0 \
  --region "$DR_REGION"
echo "✅ DR ASG scaled to 0 — no running instances (cost saving restored)"

# ─── STEP 4: Snapshot DR RDS Before Cleanup ──────────────────────────────────
echo ""
echo "[STEP 4/5] Taking final snapshot of DR RDS before cleanup..."
SNAP_ID="saa-dr-final-snapshot-$(date +%Y%m%d-%H%M%S)"
aws rds create-db-snapshot \
  --db-instance-identifier "$DR_RDS_ID" \
  --db-snapshot-identifier "$SNAP_ID" \
  --region "$DR_REGION"
echo "✅ Snapshot started: $SNAP_ID"
echo "   (Wait for snapshot to complete before deleting DR RDS instance)"
echo "   Check status: aws rds describe-db-snapshots --db-snapshot-identifier $SNAP_ID --region $DR_REGION"

# ─── STEP 5: Summary ─────────────────────────────────────────────────────────
FAILBACK_END=$(date +%s)
DURATION=$(( FAILBACK_END - FAILBACK_START ))

echo ""
echo "============================================================"
echo "  ✅ FAILBACK COMPLETE"
echo "  Duration: ~${DURATION} seconds"
echo ""
echo "  POST-FAILBACK TASKS:"
echo "  1. Confirm traffic is flowing to primary in CloudWatch"
echo "  2. Wait for DR RDS snapshot to complete, then:"
echo "     aws rds delete-db-instance \\"
echo "       --db-instance-identifier $DR_RDS_ID \\"
echo "       --skip-final-snapshot \\"
echo "       --region $DR_REGION"
echo "  3. Create a new read replica from primary for next DR test:"
echo "     See: cloudformation/primary-region.yaml > Outputs > CreateReplicaCommand"
echo "  4. Document lessons learned from this DR event"
echo "  5. Schedule a DR drill within the next 90 days"
echo "============================================================"
