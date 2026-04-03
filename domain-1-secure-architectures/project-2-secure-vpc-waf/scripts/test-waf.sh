#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 1.2 - WAF Test Script
# Replace ALB_DNS with your actual ALB DNS name before running
# ─────────────────────────────────────────────────────────────────────────────

ALB_DNS="SAA-WebApp-ALB-1234567890.us-east-1.elb.amazonaws.com" #Replace this with the newly created ALB name

echo "=========================================="
echo "  AWS WAF Test Suite - SAA Study Project"
echo "=========================================="

echo ""
echo "[TEST 1] Normal request - should return 200"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$ALB_DNS/"

echo ""
echo "[TEST 2] SQL Injection attempt - should return 403"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
  "http://$ALB_DNS/?id=1' OR '1'='1"

echo ""
echo "[TEST 3] XSS attempt in query string - should return 403"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
  "http://$ALB_DNS/?q=<script>alert('xss')</script>"

echo ""
echo "[TEST 4] Rate limit test - send 110 requests rapidly"
echo "Sending 110 requests... (first 100 should be 200, rest 403)"
for i in $(seq 1 110); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/")
  echo "Request $i: HTTP $STATUS"
done

echo ""
echo "=========================================="
echo "  Check WAF logs in CloudWatch:"
echo "  CloudWatch > Log Groups > aws-waf-logs-*"
echo "=========================================="
