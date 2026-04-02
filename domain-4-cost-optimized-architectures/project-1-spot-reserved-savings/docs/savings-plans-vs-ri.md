# Savings Plans vs Reserved Instances
## SAA Study Project 4.1 – Exam Reference

---

## Quick Comparison

| | Standard RI | Convertible RI | EC2 Savings Plan | Compute Savings Plan |
|---|---|---|---|---|
| **Discount** | Up to 72% | Up to 66% | Up to 66% | Up to 66% |
| **Change instance type** | ❌ No | ✅ Yes | ✅ (within family) | ✅ Any |
| **Change region** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Applies to Fargate** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Applies to Lambda** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Term** | 1 or 3 years | 1 or 3 years | 1 or 3 years | 1 or 3 years |
| **Payment options** | All/Partial/No upfront | All/Partial/No | All/Partial/No | All/Partial/No |
| **Flexibility** | Least | More | More | Most |

---

## Payment Options (More Upfront = Higher Discount)

1. **All Upfront**: highest discount, pay everything at start
2. **Partial Upfront**: pay some now, rest monthly — medium discount
3. **No Upfront**: pay monthly — lowest discount of the three

---

## When to Choose Each

### Standard Reserved Instances
- You KNOW exactly which instance type, size, and region you'll use for 1–3 years
- Maximum discount when you can commit to specifics
- Example: "We always run 10 × m5.xlarge in us-east-1 for our web tier"

### Convertible Reserved Instances
- You want high discount but need flexibility to change instance family/size later
- Example: "We plan to run r5 now but might switch to r6i in 6 months"

### EC2 Savings Plan
- Flexible within the same instance family in one region
- Automatically applies to any EC2 instance in that family
- Example: commit $100/hr to EC2 → applies to any t3/t2 instances

### Compute Savings Plan
- Most flexible — applies to EC2 (any family, size, region), Fargate, and Lambda
- Best when you use a mix of services or plan to shift between them
- Example: use Lambda today, might migrate to Fargate next year

---

## Spot Instances — Key Facts for the Exam

- **Discount**: up to 90% vs On-Demand
- **Interruption**: AWS can reclaim with 2-minute warning
- **Good for**: batch processing, ML training, video encoding, CI/CD
- **Bad for**: databases, stateful apps, anything that can't be interrupted
- **Spot Fleet**: mix of Spot + On-Demand, maintains target capacity
- **Capacity-optimised allocation**: picks pools with most available capacity (lower interruption rate)
- **Lowest-price allocation**: picks cheapest Spot pool (higher interruption risk)

### Spot Interruption Handling
1. Detect interruption: poll `169.254.169.254/latest/meta-data/spot/termination-time`
2. Save state to S3
3. Drain from ALB target group
4. Send alert via SNS
5. Let instance terminate gracefully

---

## Dedicated Hosts vs Dedicated Instances

| | Dedicated Host | Dedicated Instance |
|---|---|---|
| Physical server | Yes — same server | No — just isolated hardware |
| BYOL licensing | ✅ Yes (socket/core-based) | ❌ No |
| Visibility into sockets/cores | ✅ Yes | ❌ No |
| Cost | Higher | Slightly lower |
| Use case | Software licensing compliance | Hardware isolation requirement |

---

## Exam Tips

- "Reduce EC2 costs for steady-state workload" → **Reserved Instances or Savings Plans**
- "Flexible compute savings across EC2 + Lambda + Fargate" → **Compute Savings Plan**
- "Fault-tolerant batch jobs at lowest cost" → **Spot Instances**
- "Need physical server with BYOL licensing" → **Dedicated Host**
- "Hardware isolation, no licensing requirement" → **Dedicated Instance**
- All upfront payment > partial upfront > no upfront (in terms of discount amount)
