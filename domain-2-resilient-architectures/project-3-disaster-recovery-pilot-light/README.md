# Project 2.3 – Disaster Recovery: Pilot Light Strategy

**Domain:** Design Resilient Architectures  
**Difficulty:** ⭐⭐⭐⭐  
**Estimated Time:** 5–6 hours  
**Approx Cost:** ~$5–10 (minimal standby resources; delete after)

---

## 🎯 What You'll Build

A cross-region Pilot Light DR setup where:
- Primary region (us-east-1) runs the full production workload
- DR region (us-west-2) has only the minimal "pilot light" running:
  - RDS read replica (promoted during failover)
  - Stopped EC2 instances (pre-configured AMIs ready to start)
  - Route 53 health check + failover routing
- Failover is semi-automated and achievable within RTO of ~15 minutes

---

## 🏗️ Architecture Overview

```
PRIMARY (us-east-1) — Full Workload
├── EC2 Auto Scaling Group (running)
├── RDS MySQL Primary (running, Multi-AZ)
└── Route 53: saa-study.example.com → Primary ALB (weight: primary)

DR (us-west-2) — Pilot Light
├── EC2 AMI (stored, instances STOPPED to save cost)
├── RDS Read Replica (running — continuous replication from primary)
└── Route 53 Health Check → failover record → DR ALB

FAILOVER TRIGGER (Route 53 health check fails primary)
│
├── Step 1: Promote RDS read replica → standalone DB (us-west-2)
├── Step 2: Start stopped EC2 instances from pre-baked AMI
├── Step 3: Update app config to point to new RDS endpoint
└── Step 4: Route 53 automatically routes to DR ALB
```

---

## 📋 What You'll Learn

- Four DR strategies: Backup/Restore, Pilot Light, Warm Standby, Active-Active
- RTO vs RPO and how each DR strategy meets different objectives
- Cross-region RDS read replicas and promotion
- Route 53 health checks and failover routing policies
- AMI creation and cross-region copying
- CloudFormation StackSets for multi-region deployments

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Deploy Primary Region (us-east-1) (1 hour)
1. Deploy `cloudformation/primary-region.yaml` in us-east-1
2. Creates: VPC, EC2 ASG, ALB, RDS MySQL primary
3. Note the RDS endpoint — you'll need it for the replica
4. Create an AMI of one running EC2 instance: `saa-dr-webapp-ami`
5. Copy the AMI to us-west-2: EC2 → AMIs → Copy → select us-west-2

### Phase 2: Set Up RDS Read Replica in DR Region (30 min)
1. In RDS → select your primary instance → Actions → Create read replica.
2. `DB instance identifier:` __**saa-primary-readreplica**__
3. Destination region: us-west-2
4. Instance class: db.t3.micro (smallest for cost)
5. Under `Availability`, leave `Multi-AZ DB instance deployment` as default.
5. Under `Monitoring`, uncheck `Enhance Enhanced monitoring`
6. Note: read replica is running continuously — this is the "pilot light"
7. Verify replication lag in CloudWatch: `ReplicaLag` metric should be < 1 second

### Phase 3: Prepare DR Region Resources (30 min)
1. Deploy `cloudformation/dr-region.yaml` in us-west-2
2. Creates: VPC, ALB, Launch Template (using copied AMI), ASG with desired=0
3. ASG desired capacity = 0 (no instances running) = cost savings
4. EC2 instances will be started during failover
5. RDS read replica endpoint is configured in Launch Template user data

### Phase 4: Configure Route 53 Failover (45 min)
1. Create a Route 53 hosted zone: `saa-study.com` (or use an existing one)
2. `Type`: Public
2. Create a **health check** for the Primary ALB DNS:
   - Protocol: HTTP, Path: `/health`, interval: 30s, threshold: 3 failures
3. Create **Primary record**: `saa-study.example.com` → Primary ALB (failover: PRIMARY)
   - Associate the health check
4. Create **Secondary record**: `saa-study.example.com` → DR ALB (failover: SECONDARY)
   - No health check needed on secondary
5. Test: access `saa-study.example.com` → should hit primary

### Phase 5: Execute and Test DR Failover (1 hour)
1. **Simulate primary failure**: Stop all EC2 instances in us-east-1
2. Watch Route 53 health check fail (takes ~90 seconds)
3. Execute the DR runbook (`scripts/dr-failover.sh`):
   ```bash
   # Step 1: Promote RDS read replica
   aws rds promote-read-replica \
     --db-instance-identifier saa-dr-replica \
     --region us-west-2
   
   # Step 2: Scale up DR ASG
   aws autoscaling update-auto-scaling-group \
     --auto-scaling-group-name saa-dr-asg \
     --desired-capacity 2 \
     --region us-west-2
   ```
4. Wait for EC2 instances to pass health checks in DR
5. Verify: `saa-study.example.com` now routes to DR region
6. Measure your actual RTO (time from failure to traffic restored)

### Phase 6: DR Strategy Comparison Exercise (30 min)
Review `docs/dr-strategy-comparison.md` which maps each strategy to:
- RTO/RPO targets
- Cost (relative)
- AWS services used
- When to use each one (this is heavily tested on the exam!)

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/primary-region.yaml` | Full primary region stack |
| `cloudformation/dr-region.yaml` | Minimal DR (pilot light) stack |
| `scripts/dr-failover.sh` | Automated DR execution runbook |
| `scripts/dr-failback.sh` | Return to primary after recovery |
| `docs/dr-strategy-comparison.md` | Backup/Restore vs Pilot Light vs Warm Standby vs Active-Active |

---

## 🧹 Cleanup

1. Delete CloudFormation stacks in both regions
2. Delete Route 53 records and health checks
3. Delete copied AMI in us-west-2 and associated snapshots

---

## 📝 Exam Topics Covered

- ✅ DR strategies: Backup/Restore, Pilot Light, Warm Standby, Active-Active
- ✅ RPO (data loss tolerance) vs RTO (recovery time)
- ✅ Cross-region RDS read replicas and promotion
- ✅ Route 53 health checks and failover routing policy
- ✅ AMI creation and cross-region copying
- ✅ Auto Scaling Group with desired=0 for cost-effective standby
