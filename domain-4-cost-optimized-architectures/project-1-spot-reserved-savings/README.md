# Project 4.1 – Spot + Reserved Instance Strategy

**Domain:** Design Cost-Optimized Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3–4 hours  
**Approx Cost:** Minimal (Spot Instances are cheapest EC2 option; On-Demand used briefly)

---

## 🎯 What You'll Build

A cost-optimised mixed compute fleet:
- On-Demand baseline for critical, steady workloads
- Spot Instances for fault-tolerant, interruptible batch jobs
- Reserved Instances (conceptual) for predictable 1-year workloads
- Savings Plans (conceptual) for flexible discounts
- AWS Compute Optimizer recommendations review
- Mixed instances Auto Scaling Group (On-Demand base + Spot overflow)

---

## 🏗️ Architecture Overview

```
Compute Fleet Strategy:
├── Baseline (20% of capacity)
│   └── On-Demand Instances: t3.medium
│       Guaranteed availability, no interruption
│
├── Steady Workload (covered by Reserved/Savings Plans)
│   └── 1-year Reserved Instances or Compute Savings Plan
│       Up to 72% discount vs On-Demand
│
└── Burst/Batch Capacity (80% of capacity)
    └── Spot Instances: mixed types (t3.medium, t3.large, m5.large)
        Up to 90% discount, but can be interrupted with 2-min notice

Mixed Instance Auto Scaling Group:
├── On-Demand base capacity: 2 instances
├── Spot allocation strategy: capacity-optimised
└── Instance types: t3.medium, t3.large, m5.medium (multiple pools)
```

---

## 📋 What You'll Learn

- EC2 purchasing options: On-Demand, Reserved, Savings Plans, Spot, Dedicated
- Spot Instance interruption handling (2-minute warning)
- Mixed Instances Auto Scaling Group
- Spot allocation strategies: lowest-price vs capacity-optimised
- AWS Compute Optimizer recommendations
- How to right-size instances

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Understand Pricing (No AWS needed — 30 min)
1. Open [EC2 Pricing Calculator](https://instances.vantage.sh/) and compare:
   - t3.medium: On-Demand vs 1yr Reserved (No Upfront) vs Spot
   - Note: Spot prices fluctuate — check the Spot Price History
2. In the AWS Console → EC2 → Spot Requests → Spot Price History
   - Select t3.medium in us-east-1a — see price history over 90 days
   - Check availability zones: different AZs have different Spot prices
3. Fill in `docs/pricing-worksheet.md` with current prices you find

### Phase 2: Launch a Spot Instance (30 min)
1. EC2 → Launch Instance → configure a t3.micro
2. In "Advanced Details" → Purchasing option: **Request Spot Instances**
3. Set maximum price: leave as current On-Demand price (safe default)
4. Launch the instance
5. Go to EC2 → Spot Requests — see your active Spot request
6. Note: if Spot capacity is unavailable, instance won't launch

### Phase 3: Handle Spot Interruption (45 min)
1. Review `scripts/spot-interruption-handler.sh`
2. This script polls the EC2 metadata endpoint every 5 seconds:
   ```bash
   TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
   curl -H "X-aws-ec2-metadata-token: $TOKEN" \
     http://169.254.169.254/latest/meta-data/spot/termination-time
   ```
3. When interruption is detected, the script gracefully:
   - Saves work in progress to S3
   - Drains from ALB target group
   - Sends SNS notification
4. Run this as a background process on all Spot instances

### Phase 4: Create a Mixed Instances Auto Scaling Group (1 hour)
1. Deploy `cloudformation/mixed-asg.yaml`
2. Creates an ASG with:
   - On-Demand base: 2 instances (guaranteed)
   - Spot instances: fill remaining capacity
   - Multiple instance types: t3.medium, t3.large, m5.large
   - Allocation strategy: capacity-optimised (lower interruption rate)
3. Scale the ASG: desired → 6 instances
4. Check which instances are Spot vs On-Demand in the console
5. Terminate a Spot instance manually — ASG replaces it automatically

### Phase 5: Review Compute Optimizer (30 min)
1. Enable AWS Compute Optimizer (free service)
2. Wait 24 hours OR review the demo findings in `docs/compute-optimizer-sample.md`
3. Compute Optimizer analyzes CloudWatch metrics and suggests:
   - **Over-provisioned**: "Downsize from m5.xlarge to t3.large (save 60%)"
   - **Under-provisioned**: "Upgrade from t2.micro, CPU is at 95%"
4. This is the right-sizing exercise — a core cost optimization task

### Phase 6: Savings Plans vs Reserved Instances Comparison (30 min)
Review `docs/savings-plans-vs-ri.md` for the detailed comparison. Key exam concepts:
- Standard RI: biggest discount, least flexible (specific instance type)
- Convertible RI: smaller discount, can change instance family
- Compute Savings Plan: most flexible (any EC2, Fargate, Lambda)

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/mixed-asg.yaml` | Mixed On-Demand + Spot ASG |
| `scripts/spot-interruption-handler.sh` | Spot interruption detector and graceful shutdown |
| `docs/pricing-worksheet.md` | Fill in with current AWS prices |
| `docs/savings-plans-vs-ri.md` | Reserved vs Savings Plans comparison |
| `docs/compute-optimizer-sample.md` | Sample Compute Optimizer recommendations |

---

## 🧹 Cleanup

1. Delete CloudFormation stack (ASG and instances terminate)
2. Cancel any open Spot requests

---

## 📝 Exam Topics Covered

- ✅ EC2 purchasing options: On-Demand, Spot, Reserved, Savings Plans
- ✅ Spot Instance interruption (2-minute warning)
- ✅ Mixed Instances Auto Scaling Group
- ✅ Spot allocation strategies
- ✅ Savings Plans vs Reserved Instances
- ✅ AWS Compute Optimizer right-sizing
- ✅ Dedicated Hosts vs Dedicated Instances
