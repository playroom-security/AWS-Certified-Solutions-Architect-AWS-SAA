# Project 4.4 – Serverless vs EC2 Cost Comparison

**Domain:** Design Cost-Optimized Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–5 hours  
**Approx Cost:** Free Tier eligible (Lambda free tier is very generous)

---

## 🎯 What You'll Build

Deploy the SAME workload in two ways and compare cost + performance:
- Version A: EC2-based (t3.small, always-on)
- Version B: AWS Lambda + API Gateway (pay-per-request)
- Cost analysis across different traffic patterns
- NAT Gateway cost analysis and optimisation
- VPC endpoint vs NAT Gateway cost comparison

---

## 🏗️ Architecture Overview

```
WORKLOAD: Image Thumbnail Generator API
Input: image URL → Output: resized thumbnail stored in S3

VERSION A — EC2-Based:
Client → ALB → EC2 (t3.small) → S3
Cost: $0.0208/hr × 24hr × 30 days = ~$15/month (running 24/7)
      Plus: ALB ($0.008/LCU/hr), EBS storage

VERSION B — Serverless:
Client → API Gateway → Lambda → S3
Cost: pay per invocation
      First 1M requests free, then $0.20/1M
      First 400,000 GB-seconds free, then $0.0000166667/GB-second

BREAK-EVEN ANALYSIS:
At low traffic (<  500 req/day): Lambda is cheaper
At high traffic (> 1,000,000 req/day): EC2 may be cheaper
At very high traffic: consider EC2 Reserved for predictable workloads

NAT GATEWAY COST TRAP:
├── Problem: Lambda in VPC must route through NAT Gateway to reach S3
│   Cost: $0.045/hr + $0.045/GB data processed = EXPENSIVE!
└── Solution: S3 VPC Endpoint (PrivateLink) = FREE for S3 access from VPC
```

---

## 📋 What You'll Learn

- Lambda pricing: invocations + duration + memory
- When Lambda is cheaper than EC2 (and when it's not)
- NAT Gateway cost: often the hidden cost in Lambda + VPC architectures
- VPC Endpoints (PrivateLink) for free private access to AWS services
- API Gateway pricing: REST vs HTTP API cost difference
- AWS Lambda Power Tuning (find the optimal memory setting)

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Deploy EC2-Based API (30 min)
1. Deploy `cloudformation/ec2-api.yaml`
2. Creates: t3.small EC2, ALB, Auto Scaling Group (desired=1)
3. The EC2 instance runs a simple Flask API that:
   - Accepts image URL POST request
   - Downloads, resizes, uploads to S3
   - Returns the S3 URL
4. Note the monthly cost in `docs/cost-calculator.md`

### Phase 2: Deploy Serverless API (45 min)
1. Deploy `cloudformation/serverless-api.yaml`
2. Creates: API Gateway (HTTP API) → Lambda → S3
3. Lambda configuration:
   - Runtime: Python 3.12
   - Memory: 512 MB (we'll tune this)
   - Timeout: 30 seconds
4. Test both APIs with the same image resize request

### Phase 3: Find the Optimal Lambda Memory (45 min)
Lambda memory also controls CPU — more memory = more CPU = faster execution = lower duration cost.

1. Deploy the AWS Lambda Power Tuning tool (Step Functions-based)
2. Or manually test different memory settings:
```bash
for MEMORY in 128 256 512 1024 2048; do
  aws lambda update-function-configuration \
    --function-name saa-thumbnail-generator \
    --memory-size $MEMORY

  # Time 10 invocations at each memory setting
  for i in {1..10}; do
    aws lambda invoke \
      --function-name saa-thumbnail-generator \
      --payload file://events/test-image.json \
      --log-type Tail \
      output.json | grep -o '"Duration": [0-9.]*'
  done
done
```
3. Record results in `docs/memory-tuning-results.md`
4. Calculate cost = invocations × duration × (memory/1024) × price/GB-second
5. Find the memory setting where cost is lowest

### Phase 4: Analyse the NAT Gateway Cost Trap (45 min)
1. Deploy Lambda in a VPC (to access RDS in private subnet)
2. Without VPC endpoint: Lambda → NAT Gateway → S3
   - NAT Gateway: $0.045/hr = $32.40/month even if Lambda never runs!
   - Plus $0.045 per GB of data processed
3. Add an S3 VPC Endpoint:
```bash
aws ec2 create-vpc-endpoint \
  --vpc-id YOUR_VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids YOUR_PRIVATE_RT_ID
```
4. Now Lambda → S3 goes through the VPC endpoint (FREE, no NAT Gateway needed)
5. Estimate annual savings with `scripts/nat-cost-calculator.py`

### Phase 5: REST API Gateway vs HTTP API Cost (20 min)
Review `docs/api-gateway-comparison.md`:
- REST API: $3.50 per million requests (more features)
- HTTP API: $1.00 per million requests (65% cheaper, fewer features)
- For most Lambda backends: HTTP API is the right choice

### Phase 6: Traffic-Based Cost Comparison (30 min)
Fill in the cost worksheet in `docs/cost-calculator.md`:

| Traffic Level | EC2 (t3.small) | Lambda + HTTP API | Winner |
|---|---|---|---|
| 100 req/day | $15/month | < $0.01/month | Lambda |
| 10,000 req/day | $15/month | ~$0.30/month | Lambda |
| 1M req/day | $15/month | ~$30/month | EC2 |
| 10M req/day | $45/month (3 instances) | ~$300/month | EC2 |

Conclusion: Lambda wins at low/medium traffic; EC2 Reserved wins at very high, predictable traffic.

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/ec2-api.yaml` | EC2-based thumbnail API |
| `cloudformation/serverless-api.yaml` | Lambda + API Gateway thumbnail API |
| `lambda/thumbnail-generator.py` | Lambda function: resize and upload to S3 |
| `scripts/nat-cost-calculator.py` | Calculate NAT Gateway annual cost |
| `scripts/compare-apis.sh` | Benchmark both APIs with identical requests |
| `docs/cost-calculator.md` | Fill-in cost comparison worksheet |
| `docs/api-gateway-comparison.md` | REST API vs HTTP API feature/cost comparison |
| `docs/memory-tuning-results.md` | Lambda memory vs cost results table |

---

## 🧹 Cleanup

1. Delete both CloudFormation stacks
2. Delete S3 bucket with thumbnail uploads
3. Delete VPC endpoint if created

---

## 📝 Exam Topics Covered

- ✅ Lambda pricing model (invocations + GB-seconds)
- ✅ EC2 vs Lambda cost trade-offs
- ✅ NAT Gateway cost and the VPC endpoint solution
- ✅ API Gateway: REST API vs HTTP API
- ✅ Lambda memory/CPU relationship
- ✅ VPC Endpoints (Gateway and Interface types)
- ✅ Right-sizing and compute optimisation
