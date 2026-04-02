# Aurora vs RDS – Exam Reference
## SAA Study Project 3.4

---

## Aurora vs RDS MySQL: Key Differences

| Feature | Aurora MySQL | RDS MySQL |
|---|---|---|
| **Performance** | Up to 5x faster | Standard MySQL |
| **Storage** | Shared, auto-grows to 128 TB | Attached EBS, max 64 TB |
| **Storage replicas** | 6 copies across 3 AZs (auto) | 2 copies (Multi-AZ only) |
| **Failover time** | < 30 seconds | ~60–120 seconds |
| **Read replicas** | Up to 15 | Up to 5 |
| **Replica lag** | Typically < 100ms | Higher (async replication) |
| **Backtrack** | Yes (rewind DB without restore) | No |
| **Serverless option** | Yes (Aurora Serverless v2) | No |
| **Global database** | Yes (< 1s cross-region) | No (use read replicas) |
| **Cost** | ~20% more than RDS | Lower baseline cost |
| **MySQL compatibility** | Yes ✅ | Yes ✅ |

---

## Aurora Architecture Deep Dive

### Shared Cluster Storage
- Storage is NOT attached to individual instances
- All instances in the cluster share the same distributed storage volume
- 6 copies of data across 3 AZs (writes to 4, reads from 3 quorum)
- Storage auto-grows in 10 GB increments — you never provision storage

### Endpoints
| Endpoint | Routes To | Use For |
|---|---|---|
| **Cluster endpoint** | Writer instance | All writes, DDL, transactions |
| **Reader endpoint** | Load-balanced replicas | Read-only queries |
| **Instance endpoint** | Specific instance | Diagnostics, specific replica |

### Failover Order
When the writer fails:
1. If a replica exists → promoted to writer (< 30 seconds)
2. Aurora creates a new writer in the same AZ as failed instance
3. DNS is updated to point to new writer

You can set priority tiers (0–15) on replicas to control promotion order.

---

## RDS Proxy — When and Why

### The Problem (Without Proxy)
- Lambda functions open a new DB connection on every invocation
- Under load: 1000 concurrent Lambdas = 1000 simultaneous connections
- Aurora/RDS has connection limits (e.g., db.t3.medium = ~300 connections)
- Result: "Too many connections" errors

### The Solution (With RDS Proxy)
- Proxy maintains a warm pool of connections to the DB
- Applications connect to the Proxy (not the DB directly)
- Proxy multiplexes many app connections onto fewer DB connections
- Connection reuse dramatically reduces DB connection overhead

### When to Use RDS Proxy
- ✅ Lambda functions accessing RDS/Aurora
- ✅ Applications with highly variable connection counts
- ✅ Applications that open/close connections frequently
- ❌ Applications with long-lived, stable connection pools (e.g., web servers with pg-pool)

---

## Database Selection Cheat Sheet

| Requirement | Choose |
|---|---|
| Relational, MySQL-compatible, high performance | Aurora MySQL |
| Relational, PostgreSQL-compatible | Aurora PostgreSQL or RDS PostgreSQL |
| Relational, simple, cost-effective | RDS MySQL / RDS PostgreSQL |
| No-SQL, key-value, single-digit millisecond | DynamoDB |
| In-memory, cache, session store | ElastiCache Redis |
| In-memory, simple caching, multi-threaded | ElastiCache Memcached |
| Graph database | Amazon Neptune |
| Time-series data | Amazon Timestream |
| Document store (MongoDB-compatible) | Amazon DocumentDB |
| Analytics / data warehouse (columnar) | Amazon Redshift |
| Ledger / immutable audit log | Amazon QLDB |

---

## Exam Tips

- "Automatic failover" for RDS = **Multi-AZ** (same region, standby)
- "Read scaling" for RDS = **Read Replicas** (async, can be cross-region)
- "Both HA and read scaling" = **Aurora** (all replicas can serve reads AND be promoted to writer)
- Aurora Multi-Master is deprecated — don't confuse with active-active
- Aurora Serverless v2: scales instantly, billed per ACU-second, great for unpredictable workloads
