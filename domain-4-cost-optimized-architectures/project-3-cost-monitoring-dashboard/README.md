# Project 4.3 – Cost Monitoring Dashboard

**Domain:** Design Cost-Optimized Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3 hours  
**Approx Cost:** Free (Cost Explorer, Budgets, and basic CloudWatch are free)

---

## 🎯 What You'll Build

A complete cost monitoring and alerting system:
- AWS Budgets with email + SNS alerts at 80% and 100% of threshold
- Cost Explorer saved reports (service breakdown, daily trends)
- CloudWatch dashboard showing cost metrics alongside operational metrics
- Cost Allocation Tags for project-level cost tracking
- Cost and Usage Report (CUR) delivered to S3 for Athena analysis
- AWS Trusted Advisor cost-saving check review

---

## 🏗️ Architecture Overview

```
Cost Monitoring Stack:
│
├── AWS Budgets
│   ├── Monthly Budget: $50/month (total account)
│   │   ├── Alert at 80%: email + SNS
│   │   └── Alert at 100%: email + SNS + potential auto-stop
│   └── Service Budget: $20/month for EC2 only
│
├── Cost Explorer
│   ├── Saved report: daily costs by service (last 30 days)
│   ├── Saved report: costs by tag (Project: SAA-Study)
│   └── RI Coverage report (track Reserved Instance utilisation)
│
├── Cost and Usage Report (CUR)
│   └── Delivered to S3 hourly → queryable via Athena
│
├── CloudWatch Dashboard: SAA-Cost-Dashboard
│   ├── Estimated charges (billing metric)
│   ├── EC2 running instance count
│   ├── RDS storage consumed
│   └── S3 bucket size
│
└── Cost Allocation Tags
    ├── Project: SAA-Study
    ├── Domain: Domain1/2/3/4
    └── Environment: Dev/Prod
```

---

## 📋 What You'll Learn

- AWS Budgets: types (cost, usage, RI coverage, Savings Plans coverage)
- Cost Explorer: filtering, grouping, and forecasting
- Cost Allocation Tags: activating and using for chargeback
- Cost and Usage Report (CUR): the most detailed billing data
- AWS Trusted Advisor: cost optimisation checks
- CloudWatch Billing alarms

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Enable Cost Allocation Tags (15 min)
1. Billing → Cost Allocation Tags → AWS-Generated Tags → activate `aws:createdBy`
2. Billing → Cost Allocation Tags → User-Defined Tags → activate `Project`, `Domain`, `Environment`
3. Note: tags must be activated here to appear in Cost Explorer (takes 24 hours)
4. Go back through projects 1.1–4.2 and ensure all resources have `Project: SAA-Study`

### Phase 2: Create AWS Budgets (30 min)
1. Deploy `cloudformation/budgets.yaml` or create manually:
2. **Budget 1**: Total account monthly cost
   - Budget amount: $50
   - Alert 1: 80% actual → email you
   - Alert 2: 100% actual → email + SNS topic
   - Alert 3: 100% forecasted → email (predictive alert!)
3. **Budget 2**: EC2 service budget
   - Filter by service: EC2-Instances
   - Budget: $20/month
4. **Budget 3**: RI Utilisation budget
   - Type: Reserved Instance Utilisation
   - Alert if utilisation drops below 80%

### Phase 3: Configure Cost and Usage Report (20 min)
1. Billing → Cost & Usage Reports → Create report
2. Report name: `saa-study-cur`
3. S3 bucket: create `saa-cur-ACCOUNT_ID` in us-east-1
4. Granularity: Hourly
5. Format: Parquet (for Athena)
6. Report takes 24 hours to start populating

### Phase 4: Explore Cost Explorer (45 min)
In Cost Explorer, practice these views (these are exam-relevant):
1. **Service breakdown**: last 30 days by service — which service costs most?
2. **Daily trend**: spot any unexpected spikes
3. **Tag filter**: filter by `Project: SAA-Study` to see your study costs only
4. **Forecast**: what will next month cost at current rate?
5. Save 2–3 reports for ongoing monitoring

### Phase 5: Create CloudWatch Billing Alarm (20 min)
1. CloudWatch → Alarms → Create (must be in us-east-1 for billing metrics!)
2. Metric: Billing → Total Estimated Charge
3. Condition: greater than $30
4. Action: notify SNS topic → email
5. This is your safety net: alerts you before the Budget threshold

### Phase 6: Review Trusted Advisor (20 min)
1. Go to AWS Trusted Advisor
2. Cost Optimisation category — review findings:
   - Idle EC2 instances (< 2% CPU for 14+ days)
   - Unassociated Elastic IP addresses (charged even when not attached!)
   - Underutilised EBS volumes
   - Low-utilisation RDS instances
3. Note: full Trusted Advisor checks require Business or Enterprise Support plan

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/budgets.yaml` | AWS Budgets with SNS alerts |
| `cloudformation/cloudwatch-dashboard.yaml` | CloudWatch cost + ops dashboard |
| `scripts/tag-all-resources.sh` | Apply cost tags to all running resources |
| `athena-queries/cost-by-service.sql` | Query CUR data with Athena |
| `docs/cost-optimisation-checklist.md` | Monthly cost review checklist |

---

## 🧹 Cleanup

No resources to delete! (Cost Explorer, Budgets, and monitoring are free)

Only clean up the CUR S3 bucket if you want.

---

## 📝 Exam Topics Covered

- ✅ AWS Budgets (cost, usage, RI, Savings Plans types)
- ✅ Cost Explorer (filtering, grouping, forecasting)
- ✅ Cost Allocation Tags
- ✅ Cost and Usage Report (CUR)
- ✅ CloudWatch billing alarms
- ✅ AWS Trusted Advisor cost checks
- ✅ Multi-account billing with AWS Organizations
