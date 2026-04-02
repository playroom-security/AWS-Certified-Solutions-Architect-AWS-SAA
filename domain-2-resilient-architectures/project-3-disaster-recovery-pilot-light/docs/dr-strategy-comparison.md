# Disaster Recovery Strategy Comparison
## SAA Study Project 2.3 – Key Exam Reference

---

## The Four DR Strategies (Know These Cold!)

| Strategy | RTO | RPO | Cost | Description |
|---|---|---|---|---|
| **Backup & Restore** | Hours | Hours | 💲 Lowest | Back up data to S3/Glacier. Restore from scratch during disaster. No standby infra. |
| **Pilot Light** | 10–30 min | Minutes | 💲💲 Low | Minimal core runs in DR (DB replica). Scale out compute during failover. |
| **Warm Standby** | Minutes | Seconds | 💲💲💲 Medium | Scaled-down but fully functional copy in DR. Scale up during failover. |
| **Active-Active** | Near-zero | Near-zero | 💲💲💲💲 Highest | Full workload in multiple regions simultaneously. Route 53 routes to both. |

---

## Detailed Breakdown

### 1. Backup and Restore
- **What runs in DR?** Nothing. Just S3/Glacier backups.
- **Failover process:** Restore data, launch new instances, reconfigure
- **Best for:** Non-critical workloads, dev/test, archives
- **AWS services:** S3, S3 Glacier, AWS Backup, Data Lifecycle Manager
- **Example RTO:** 4–24 hours | **Example RPO:** 1–24 hours

### 2. Pilot Light ← *This project*
- **What runs in DR?** Only the critical data tier (RDS read replica)
- **Failover process:** Promote replica, start pre-baked EC2 AMIs, update DNS
- **Best for:** Moderate-criticality apps that can tolerate 15–30 min downtime
- **AWS services:** RDS Read Replicas, EC2 AMIs, Route 53 failover, ASG (desired=0)
- **Example RTO:** 10–30 minutes | **Example RPO:** Minutes (replication lag)

### 3. Warm Standby
- **What runs in DR?** Full application stack at minimum viable capacity
- **Failover process:** Scale up existing resources, switch DNS
- **Best for:** High-criticality apps needing RTO < 10 minutes
- **AWS services:** EC2 ASG (min 1), RDS Read Replica (running), ALB, Route 53
- **Example RTO:** 2–10 minutes | **Example RPO:** Seconds

### 4. Active-Active (Multi-Site)
- **What runs in DR?** Full production load in BOTH regions simultaneously
- **Failover process:** Route 53 stops routing to failed region (health check)
- **Best for:** Mission-critical, zero-tolerance for downtime
- **AWS services:** Route 53 weighted/latency routing, Global Accelerator, Aurora Global Database
- **Example RTO:** Seconds | **Example RPO:** Near-zero

---

## Key Exam Distinctions

### RTO vs RPO
- **RTO (Recovery Time Objective):** How long can you be down? → drives compute strategy
- **RPO (Recovery Point Objective):** How much data can you lose? → drives replication strategy

### Route 53 Routing Policies for DR
| Policy | Use Case |
|---|---|
| **Failover** | Active-passive DR (primary/secondary) |
| **Weighted** | Gradual traffic shift, active-active with unequal load |
| **Latency** | Route to lowest-latency region |
| **Geolocation** | Route by user geography |
| **Health Checks** | Works with all policies to detect failures |

### RDS Options for DR
| Option | Replication | Failover | Cross-Region |
|---|---|---|---|
| Multi-AZ | Synchronous | Automatic (~60s) | No |
| Read Replica | Asynchronous | Manual (promote) | Yes ✅ |
| Aurora Global DB | < 1s replication | < 1 min automated | Yes ✅ |

---

## Exam Tip
If a question says:
- "cheapest DR solution" → **Backup and Restore**
- "minimal footprint in DR region" → **Pilot Light**
- "RTO of a few minutes" → **Warm Standby**
- "zero downtime, zero data loss" → **Active-Active with Aurora Global**
- "automatic failover" → **Multi-AZ** (same region) or **Route 53 + health check** (cross-region)
