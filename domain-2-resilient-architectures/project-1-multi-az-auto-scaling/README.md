# Project 2.1 – Multi-AZ Web App with Auto Scaling

**Domain:** Design Resilient Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–6 hours  
**Approx Cost:** ~$5–15 (EC2 + RDS Multi-AZ; delete promptly)

---

## 🎯 What You'll Build

A highly available web application with:
- EC2 Auto Scaling Group spanning 2+ Availability Zones
- Application Load Balancer with health checks
- RDS MySQL with Multi-AZ standby (automatic failover)
- CloudWatch alarms driving scale-out and scale-in
- Session stickiness and connection draining on the ALB

---

## 🏗️ Architecture Overview

```
Internet
    │
    ▼
Application Load Balancer (multi-AZ, public subnets)
├── Listener: HTTP:80 → Target Group
├── Health Check: GET /health → expects 200
└── Stickiness: disabled (stateless app)
    │
    ├── AZ-1 (us-east-1a) ──► EC2 (t3.micro) ◄── Auto Scaling Group
    └── AZ-2 (us-east-1b) ──► EC2 (t3.micro) ◄── (min:2, desired:2, max:6)
                │
                ▼
    RDS MySQL Multi-AZ
    ├── Primary: us-east-1a
    └── Standby: us-east-1b (synchronous replication, auto-failover)
```

---

## 📋 What You'll Learn

- Auto Scaling Group: launch templates, scaling policies, health checks
- ALB target groups, health checks, and connection draining
- RDS Multi-AZ vs Read Replicas (different purposes!)
- CloudWatch alarms: CPU-based and request-count-based scaling
- What happens during an AZ failure (failover behaviour)

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Deploy the Base Infrastructure (30 min)
1. First deploy Project 1.2's VPC stack (or use `cloudformation/vpc-prereq.yaml` here)
2. Deploy `cloudformation/multi-az-webapp.yaml`
3. Stack creates: Launch Template, ASG, ALB, Target Group, RDS Multi-AZ

### Phase 2: Understand the Launch Template (30 min)
1. In EC2 → Launch Templates, open `SAA-WebApp-LT`
2. Review: AMI, instance type, security group, IAM role, User Data
3. User Data installs Apache and creates a `/health` endpoint
4. Verify: go to ALB DNS name in browser → you should see "Hello from AZ: us-east-1a/b"

### Phase 3: Configure Scaling Policies (45 min)
1. In EC2 → Auto Scaling Groups → SAA-WebApp-ASG → Automatic Scaling
2. Create a **Target Tracking** policy: maintain CPU at 50%
3. Create a **Step Scaling** policy:
   - CloudWatch alarm: CPU > 70% for 2 minutes → add 2 instances
   - CloudWatch alarm: CPU < 30% for 5 minutes → remove 1 instance
4. Set scale-in protection during business hours (simulate with a scheduled action)

### Phase 4: Simulate Load and Watch Auto Scaling (1 hour)
1. SSH into one of the EC2 instances (via Session Manager)
2. Install and run stress: `sudo yum install -y stress && stress --cpu 4 --timeout 300`
3. Watch in EC2 console as new instances launch
4. Stop the stress test — watch instances terminate (after cooldown)
5. Check CloudWatch → Auto Scaling metrics

### Phase 5: Simulate AZ Failure (45 min)
1. In EC2 → Auto Scaling Group → Suspend → Availability Zone Rebalancing
2. Terminate all instances in AZ-1 manually
3. Watch: ALB health checks fail for AZ-1 → traffic routes only to AZ-2
4. ASG launches new instances (in AZ-2 initially, then rebalances)
5. RDS: simulate failover via RDS console → Reboot with Failover
6. Observe: connection brief interruption, then auto-reconnects to new primary

### Phase 6: Test Connection Draining (15 min)
1. In ALB Target Group settings, review "Deregistration delay" (default: 300s)
2. Register a test target, start sending traffic
3. Deregister the target — observe existing connections complete before instance removed
4. This models graceful scale-in

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/multi-az-webapp.yaml` | Full stack deployment |
| `scripts/user-data.sh` | EC2 User Data: installs Apache + health endpoint |
| `scripts/load-test.sh` | Send load to ALB to trigger scaling |
| `scripts/simulate-az-failure.sh` | CLI commands to terminate AZ-1 instances |

---

## 🧹 Cleanup

1. Delete CloudFormation stack (removes ASG, ALB, RDS)
2. RDS Multi-AZ incurs double the storage cost — delete promptly

---

## 📝 Exam Topics Covered

- ✅ EC2 Auto Scaling Groups and policies
- ✅ Application Load Balancer, target groups, health checks
- ✅ RDS Multi-AZ (HA) vs Read Replicas (performance)
- ✅ Availability Zone fault tolerance
- ✅ CloudWatch alarms and metrics
- ✅ Connection draining / deregistration delay
- ✅ Horizontal vs vertical scaling
