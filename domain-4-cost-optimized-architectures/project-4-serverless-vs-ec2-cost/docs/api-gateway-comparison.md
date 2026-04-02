# API Gateway – REST API vs HTTP API
## SAA Study Project 4.4 – Cost & Feature Reference

---

## Quick Decision: Which API Gateway Type?

| Need | Use |
|---|---|
| Lambda or HTTP backend only, want lowest cost | **HTTP API** |
| Need usage plans, API keys, or WAF integration | **REST API** |
| Need request/response transformation | **REST API** |
| WebSocket support | **WebSocket API** (separate) |
| Just need to expose Lambda to internet cheaply | **HTTP API** |

---

## Pricing Comparison (us-east-1)

| | REST API | HTTP API |
|---|---|---|
| First 333 million requests/month | $3.50/million | $1.00/million |
| After 333 million | $1.51/million | $1.00/million |
| **Savings** | — | **~65–71% cheaper** |

---

## Feature Comparison

| Feature | REST API | HTTP API |
|---|---|---|
| Lambda integration | ✅ | ✅ |
| HTTP backend | ✅ | ✅ |
| AWS service integration | ✅ | ❌ |
| Usage plans & API keys | ✅ | ❌ |
| Request/response transformation | ✅ | ❌ |
| Cognito authorizer | ✅ | ✅ |
| JWT authorizer | ✅ | ✅ |
| AWS WAF integration | ✅ | ❌ |
| Cache responses | ✅ | ❌ |
| Private API | ✅ | ❌ |
| CORS support | ✅ (manual) | ✅ (built-in) |
| Automatic deployments | ❌ | ✅ |
| Latency | Higher | Lower |

---

## VPC Endpoint Types (Know for the Exam!)

### Gateway Endpoints (FREE)
- **S3** — `com.amazonaws.REGION.s3`
- **DynamoDB** — `com.amazonaws.REGION.dynamodb`
- Added to route tables (not network interfaces)
- No hourly charge, no data processing charge
- **Always add these when Lambda or EC2 in VPC needs S3/DynamoDB access**

### Interface Endpoints (PrivateLink — charged)
- All other AWS services (SNS, SQS, Secrets Manager, KMS, etc.)
- Creates an ENI in your subnet
- Cost: $0.01/hr per AZ + $0.01/GB data processed
- Use when you must keep traffic private (no internet, no NAT)

---

## Lambda Cost Formula

```
Cost = (Invocations × $0.0000002)
     + (Duration in GB-seconds × $0.0000166667)

GB-seconds = (execution_time_ms / 1000) × (memory_mb / 1024)

Example: 128 MB, 200ms execution
GB-seconds = 0.2s × 0.125 GB = 0.025 GB-seconds
Cost per invocation = $0.0000002 + (0.025 × $0.0000166667) = ~$0.0000006

At 1 million invocations: ~$0.62/month
Free tier: 1M requests + 400,000 GB-seconds/month (forever, not just 12 months!)
```

---

## When Lambda Beats EC2 (and vice versa)

### Lambda wins when:
- Traffic is unpredictable or bursty
- Many idle periods (you pay $0 when Lambda isn't running)
- Event-driven, short-duration workloads (< 15 minutes)
- Development/staging environments with low usage

### EC2 wins when:
- Traffic is high and consistent (Reserved Instance discount)
- Long-running processes (Lambda max 15 minutes)
- Need specific OS, runtime, or GPU
- Very high throughput (Lambda concurrency limits can be hit)
- Calculate break-even: EC2 cost / Lambda cost per request

### Typical break-even:
- t3.micro On-Demand: ~$8.50/month
- Lambda at $0.0000002/req = 42.5M requests to match EC2 monthly cost
- But Lambda also has duration cost — real break-even depends on workload

---

## Exam Tips

- "Pay only when code runs" → **Lambda**
- "No server management, variable traffic" → **Lambda**
- "High, steady, predictable traffic" → **EC2 Reserved Instances**
- "Lambda in VPC accessing S3 — how to avoid NAT?" → **S3 Gateway VPC Endpoint**
- "Cheapest API Gateway for Lambda backend" → **HTTP API** (65% cheaper than REST)
- "WAF protection on API Gateway" → requires **REST API** (not HTTP API)
