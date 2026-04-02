#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 2.1 - Load Test Script
# Sends HTTP load to ALB to trigger Auto Scaling policies
# Requires: curl, ab (Apache Benchmark) or hey
# ─────────────────────────────────────────────────────────────────────────────

ALB_DNS="your-alb-dns.us-east-1.elb.amazonaws.com"

echo "============================================"
echo "  Auto Scaling Load Test - SAA Study 2.1"
echo "============================================"
echo "Target: http://$ALB_DNS/"
echo ""

# Check if 'hey' is installed (preferred load testing tool)
if command -v hey &> /dev/null; then
  echo "[INFO] Using 'hey' for load testing"
  echo "[INFO] Sending 10,000 requests with 100 concurrent workers..."
  echo "[INFO] Watch EC2 Auto Scaling console for new instances launching"
  echo ""
  hey -n 10000 -c 100 -q 50 "http://$ALB_DNS/"

# Fallback to Apache Benchmark
elif command -v ab &> /dev/null; then
  echo "[INFO] Using Apache Benchmark (ab) for load testing"
  echo "[INFO] Sending 5,000 requests with 50 concurrent workers..."
  ab -n 5000 -c 50 "http://$ALB_DNS/"

# Fallback to curl loop
else
  echo "[INFO] Using curl loop (install 'hey' for better load testing)"
  echo "[INFO] Sending 500 requests..."
  for i in $(seq 1 500); do
    curl -s -o /dev/null "http://$ALB_DNS/"
    if (( i % 50 == 0 )); then
      echo "Sent $i requests..."
    fi
  done
fi

echo ""
echo "============================================"
echo "  Load test complete!"
echo "  Check:"
echo "  1. EC2 > Auto Scaling Groups > Activity"
echo "  2. CloudWatch > Alarms"  
echo "  3. EC2 > Instances (new instances launching)"
echo "============================================"
