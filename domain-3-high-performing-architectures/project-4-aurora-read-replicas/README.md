# Project 3.4 – Aurora with Read Replicas & RDS Proxy

**Domain:** Design High-Performing Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–5 hours  
**Approx Cost:** ~$10–20 (Aurora + Proxy; delete after — most expensive project!)

---

## 🎯 What You'll Build

A high-performing Aurora MySQL cluster with:
- Aurora cluster: 1 writer + 2 read replicas
- Read/write endpoint splitting in the application
- RDS Proxy for connection pooling (serverless-friendly)
- Aurora Auto Scaling for read replicas
- Performance Insights for query analysis
- Aurora Serverless v2 (optional comparison)

---

## 🏗️ Architecture Overview

```
Application
├── Write operations → Aurora Cluster Endpoint (writer)
└── Read operations  → Aurora Reader Endpoint (load-balanced to replicas)

Aurora Cluster: saa-aurora-cluster
├── Writer instance: db.r6g.large (us-east-1a)
├── Read Replica 1:  db.r6g.large (us-east-1b)
└── Read Replica 2:  db.r6g.large (us-east-1c) ← Auto Scaling adds this

Storage: Aurora shared distributed storage (6 copies across 3 AZs)
         Auto-grows in 10 GB increments, up to 128 TB

RDS Proxy (in front of Aurora)
├── Maintains warm connection pool to Aurora
├── App connects to Proxy → Proxy manages DB connections
└── Especially important for Lambda (which creates new connections per invocation!)

Auto Scaling
└── If replica CPU > 70% for 5 min → add replica (up to max 15)
```

---

## 📋 What You'll Learn

- Aurora architecture: shared storage, cluster endpoints
- Aurora vs RDS MySQL: feature comparison
- Writer endpoint vs reader endpoint
- RDS Proxy: why it matters for Lambda and connection pooling
- Aurora Auto Scaling for read replicas
- Performance Insights for identifying slow queries
- Aurora Serverless v2 vs provisioned

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create Aurora Cluster (30 min)
1. Deploy `cloudformation/aurora-cluster.yaml`
2. Creates an Aurora MySQL cluster with:
   - 1 writer instance
   - 1 read replica (we'll add a second via Auto Scaling)
3. In the RDS console, find two endpoints:
   - **Cluster endpoint** (writer): `saa-cluster.cluster-xxxx.us-east-1.rds.amazonaws.com`
   - **Reader endpoint** (replicas): `saa-cluster.cluster-ro-xxxx.us-east-1.rds.amazonaws.com`
4. Explore: Aurora uses shared cluster storage — storage is NOT tied to individual instances

### Phase 2: Test Read/Write Endpoint Splitting (45 min)
1. SSH to EC2 app server (via Session Manager)
2. Run `scripts/rw-split-demo.py` which demonstrates:
   - Writes going to the cluster (writer) endpoint
   - Reads going to the reader endpoint (load balanced across replicas)
3. Simulate high read load — check CloudWatch: replica CPU rises
4. Check `scripts/rw-split-demo.py` for how the application code handles this

### Phase 3: Set Up RDS Proxy (30 min)
1. RDS → Proxies → Create Proxy
   - Target: your Aurora cluster
   - Idle connection timeout: 1800 seconds
   - IAM authentication: enabled
   - Secrets Manager: link to your DB credentials secret
2. Note the proxy endpoint (replaces your direct Aurora endpoint)
3. Update the app to use the Proxy endpoint
4. Observe: faster Lambda cold starts, fewer "too many connections" errors

### Phase 4: Configure Auto Scaling for Replicas (20 min)
1. RDS → Clusters → saa-aurora-cluster → Actions → Add Auto Scaling
2. Metric: Average CPU Utilisation
3. Target: 70%
4. Min: 1 replica, Max: 4 replicas
5. Run the read load test: `scripts/load-test-reads.sh`
6. Watch a second replica automatically provision (~5 minutes)

### Phase 5: Explore Performance Insights (30 min)
1. RDS → Databases → writer instance → Performance Insights
2. Run some slow queries from `scripts/slow-queries.sql`
3. Observe the "Top SQL" panel — identifies your heaviest queries
4. Filter by wait events: find where queries spend their time (CPU, I/O, locks)
5. This is how you identify and fix performance bottlenecks in the real world

### Phase 6: Aurora Feature Comparison (20 min)
Review `docs/aurora-vs-rds.md` — key exam reference for choosing the right DB.

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/aurora-cluster.yaml` | Aurora cluster + replicas + RDS Proxy |
| `scripts/rw-split-demo.py` | Demo: separate read and write endpoints |
| `scripts/load-test-reads.sh` | Generate read load to trigger auto scaling |
| `scripts/slow-queries.sql` | Queries to explore Performance Insights |
| `docs/aurora-vs-rds.md` | Aurora vs RDS MySQL exam reference |

---

## 🧹 Cleanup

⚠️ **Delete immediately after use** — Aurora instances are the most expensive in these projects.

1. Delete RDS Proxy first
2. Delete Aurora cluster (and all instances)
3. Delete CloudFormation stack

---

## 📝 Exam Topics Covered

- ✅ Aurora cluster endpoints (writer vs reader)
- ✅ Aurora shared distributed storage
- ✅ RDS Proxy for connection pooling
- ✅ Aurora read replica Auto Scaling
- ✅ Aurora vs RDS MySQL trade-offs
- ✅ Performance Insights for query analysis
- ✅ Aurora Serverless v2 concepts
