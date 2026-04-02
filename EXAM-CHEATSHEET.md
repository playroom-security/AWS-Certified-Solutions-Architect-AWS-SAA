# AWS SAA-C03 Master Cheatsheet
## Built from all 16 hands-on projects

---

## DOMAIN 1 – SECURE ARCHITECTURES (30%)

### IAM Essentials
- **Root account**: lock it away, enable MFA, never use for daily tasks
- **IAM Policy evaluation**: Explicit Deny > Explicit Allow > Implicit Deny
- **SCP vs IAM**: SCP sets the maximum permissions ceiling for an account; IAM grants within that ceiling
- **Inline vs Managed policies**: prefer AWS Managed → Customer Managed → Inline (last resort)
- **AssumeRole flow**: User → `sts:AssumeRole` → gets temp credentials → acts as role
- **Permission boundary**: limits the max permissions an IAM entity can have (not a grant!)

### VPC Security
| Tool | Type | Level | Remembering |
|---|---|---|---|
| Security Group | Stateful | Instance / ENI | "SG = Stateful" |
| Network ACL | Stateless | Subnet | "NACL = Not Stateful, Numbers matter" |
| WAF | Layer 7 | ALB / CloudFront | SQL injection, XSS, rate limiting |
| Shield Standard | DDoS | Network/Transport | Always-on, free |
| Shield Advanced | DDoS | Everything | Paid, 24/7 DDoS response team |

- NACL rules are evaluated **lowest number first**; first match wins
- SGs: **allow rules only** (no deny); NACLs: **both allow and deny**
- NACLs are **stateless** → must allow both inbound AND outbound for each connection
- Default NACL: **allows all**; Custom NACL: **denies all** by default

### Encryption
- **KMS CMK**: you manage the key; KMS manages the HSM
- **SSE-S3**: Amazon manages key (AES-256, free)
- **SSE-KMS**: you choose CMK, audit via CloudTrail, has API call cost
- **SSE-C**: you provide the key; S3 uses it and discards it
- **Data in transit**: TLS/ACM for HTTPS; VPN or Direct Connect for hybrid
- **KMS key rotation**: automatic annually for CMK; does NOT re-encrypt existing data
- **Secrets Manager**: auto-rotation via Lambda; integrates with RDS/Aurora natively

### Cognito
- **User Pool**: authentication (sign-up/sign-in, JWT tokens)
- **Identity Pool**: authorization (exchange JWT for temporary AWS credentials)
- Use both together: User Pool authenticates → Identity Pool grants AWS access

---

## DOMAIN 2 – RESILIENT ARCHITECTURES (26%)

### Auto Scaling Policies
| Policy | Trigger | Good For |
|---|---|---|
| Target Tracking | Keep metric at value (e.g. CPU 70%) | Most use cases |
| Step Scaling | Multiple thresholds with different actions | Fine-grained control |
| Simple Scaling | One alarm → one action, with cooldown | Legacy |
| Scheduled | Time-based (known traffic patterns) | Business hours |
| Predictive | ML forecasts traffic, pre-scales | Spiky, predictable patterns |

### Load Balancers
| Type | Layer | Protocol | Key Feature |
|---|---|---|---|
| ALB | 7 | HTTP/HTTPS | Path routing, host routing, Lambda targets, WAF |
| NLB | 4 | TCP/UDP/TLS | Ultra-low latency, static IP, millions RPS |
| GLB | 3 | IP | Inline virtual appliances (firewalls, IDS) |
| CLB | 4+7 | HTTP/TCP | Legacy — avoid |

### High Availability Patterns
- **Multi-AZ** = HA in same region (synchronous replication, auto-failover)
- **Read Replicas** = read scaling (async replication, manual promote)
- **Aurora** = both HA and read scaling (shared storage, up to 15 replicas)
- **Route 53 failover** = cross-region DR (requires health check)

### Disaster Recovery (Memorise This Order!)
```
Cheapest ←————————————————————————→ Most Expensive
Slowest  ←————————————————————————→ Fastest

Backup/Restore | Pilot Light | Warm Standby | Active-Active
  Hours RTO    | 15-30 min  |   Minutes   |   Seconds
  Hours RPO    | Minutes    |   Seconds   |   ~Zero
```

### SQS Key Concepts
- **Standard**: at-least-once, best-effort ordering, nearly unlimited TPS
- **FIFO**: exactly-once, strict ordering, 3000 TPS (with batching)
- **Visibility timeout**: message invisible while being processed (default 30s)
- **DLQ**: moves to Dead Letter Queue after maxReceiveCount failures
- **Long polling** (20s): reduces empty responses and cost vs short polling

### Containers
- **ECS Fargate** = serverless containers (no EC2 management)
- **ECS EC2** = containers on your EC2 instances (more control)
- **EKS** = Kubernetes on AWS
- **Task Definition** = blueprint (like docker-compose); **Service** = keeps N tasks running

---

## DOMAIN 3 – HIGH-PERFORMING ARCHITECTURES (24%)

### Storage Services Cheatsheet
| Service | Type | Use Case |
|---|---|---|
| S3 | Object | Static files, backups, data lake |
| EBS | Block | EC2 boot volumes, databases |
| EFS | File (NFS) | Shared access across multiple EC2 |
| FSx for Windows | File (SMB) | Windows file shares |
| FSx for Lustre | HPC file system | ML training, HPC, high-throughput |
| Instance Store | Block (ephemeral) | Temp data, buffers, cache (lost on stop) |

### Database Selection
| Requirement | Service |
|---|---|
| Relational, MySQL/Postgres, high perf | Aurora |
| Relational, simpler/cheaper | RDS |
| Key-value, single-digit ms, infinite scale | DynamoDB |
| In-memory cache / session store | ElastiCache Redis |
| In-memory, simple, multi-threaded cache | ElastiCache Memcached |
| Graph | Neptune |
| Document (MongoDB-compatible) | DocumentDB |
| Columnar analytics / data warehouse | Redshift |
| Time-series | Timestream |

### CloudFront Key Points
- **ACM certificates for CloudFront must be in us-east-1** (global service)
- **OAC** (Origin Access Control) = modern way to restrict S3 to CloudFront only
- **Cache invalidation**: `/*` invalidates everything; costs money after first 1000/month
- **CloudFront Functions**: lightweight JS, runs at edge (viewer request/response only)
- **Lambda@Edge**: full Node.js/Python, runs at 4 event types, higher latency than CF Functions
- **Price Class**: reduce cost by serving from fewer edge locations

### Kinesis vs SQS (High-Frequency Exam Topic!)
| | Kinesis | SQS |
|---|---|---|
| Multiple consumers same data | ✅ Yes | ❌ No |
| Replay messages | ✅ Yes | ❌ No |
| Real-time analytics | ✅ Yes | ❌ No |
| Simple task decoupling | ❌ Overkill | ✅ Yes |
| Strict ordering | Per shard | FIFO only |

---

## DOMAIN 4 – COST-OPTIMIZED ARCHITECTURES (20%)

### EC2 Purchasing Options
| Option | Discount | Commitment | Interruptible | Best For |
|---|---|---|---|---|
| On-Demand | 0% | None | No | Unpredictable, short-term |
| Reserved (1yr) | up to 40% | 1 year | No | Steady, predictable |
| Reserved (3yr) | up to 60% | 3 years | No | Long-term commitment |
| Savings Plans | up to 66% | 1–3 years | No | Flexible (EC2+Lambda+Fargate) |
| Spot | up to 90% | None | Yes (2min warning) | Fault-tolerant, batch |
| Dedicated Host | ~10% savings | On-demand or reserved | No | Licensing (BYOL) |
| Dedicated Instance | higher cost | None | No | Hardware isolation |

### S3 Cost Optimisation
1. Enable lifecycle rules (biggest savings for growing data)
2. Use Intelligent-Tiering for unpredictable access
3. Glacier Deep Archive for 7+ year compliance data ($0.001/GB/month!)
4. S3 Storage Lens to identify buckets without lifecycle rules
5. Multipart upload for objects > 100 MB

### Hidden Cost Traps (Exam Loves These!)
- **NAT Gateway**: $0.045/hr + $0.045/GB — use VPC endpoints for S3/DynamoDB!
- **Data transfer OUT**: moving data out of AWS to internet has a cost
- **Cross-AZ traffic**: data between AZs in same region costs $0.01/GB each way
- **Unattached Elastic IPs**: charged if allocated but not associated with a running instance
- **RDS Multi-AZ**: doubles instance costs (standby runs but can't serve reads)
- **Idle NAT Gateways**: charged hourly even with zero traffic

### Cost Tools Reference
| Tool | Use |
|---|---|
| **Cost Explorer** | Visualise spending, filter by tag/service, forecast |
| **AWS Budgets** | Alerts when actual or forecasted cost exceeds threshold |
| **Cost and Usage Report** | Most detailed; hourly data in S3; use Athena to query |
| **Trusted Advisor** | Finds idle resources, unattached EIPs, low-utilisation instances |
| **Compute Optimizer** | Right-size EC2, Lambda memory, EBS volumes |
| **Pricing Calculator** | Estimate costs before building |

---

## SERVICES TO KNOW COLD

### Networking
- **Route 53**: DNS + health checks + routing policies (failover, weighted, latency, geo)
- **CloudFront**: CDN, edge caching, DDoS protection (Shield Standard)
- **Global Accelerator**: static IPs, routes to nearest region (NOT a CDN — no caching)
- **Direct Connect**: dedicated private connection to AWS (predictable latency)
- **VPN**: encrypted tunnel over internet (cheaper than DX, higher latency)
- **PrivateLink**: expose services privately without traffic leaving AWS network
- **Transit Gateway**: hub for connecting multiple VPCs and on-prem networks

### CloudFront vs Global Accelerator
| | CloudFront | Global Accelerator |
|---|---|---|
| Caches content? | ✅ Yes | ❌ No |
| Static IP? | ❌ No (domain) | ✅ Yes (2 Anycast IPs) |
| Best for | Static content, media | Dynamic API, gaming, IoT |
| Protocol | HTTP/HTTPS | TCP, UDP |

---

## EXAM STRATEGY TIPS

1. **"Cost-effective"** = usually Spot instances or Reserved Instances
2. **"Highly available"** = Multi-AZ, multiple AZs in ASG, ALB
3. **"Fault-tolerant"** = can survive AZ failure without human intervention
4. **"Decoupled"** = SQS between components
5. **"Serverless"** = Lambda, Fargate, DynamoDB, Aurora Serverless, S3
6. **"Managed service"** = reduce operational overhead
7. When you see "RDS failover" → **Multi-AZ** (not read replicas)
8. When you see "read scaling" → **Read Replicas** (not Multi-AZ)
9. "Migrate on-premises" → usually **AWS DMS** (database) or **Storage Gateway**
10. "Encryption at rest" → **KMS** | "in transit" → **ACM/TLS**
