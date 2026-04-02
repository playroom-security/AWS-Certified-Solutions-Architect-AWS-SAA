# Project 3.2 – ElastiCache Caching Layer for RDS

**Domain:** Design High-Performing Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–5 hours  
**Approx Cost:** ~$5–10 (cache.t3.micro node; delete after)

---

## 🎯 What You'll Build

A read-heavy web application with a Redis caching layer:
- RDS MySQL as the database of record
- ElastiCache Redis cluster in front of RDS
- Lazy loading (cache-aside) caching pattern
- Write-through caching pattern comparison
- Cache eviction and TTL strategies
- CloudWatch monitoring of cache hit/miss rates

---

## 🏗️ Architecture Overview

```
Application (EC2 / Lambda)
        │
        ├─► ElastiCache Redis (cache.t3.micro, 2 nodes)
        │   ├── Primary node: reads AND writes
        │   ├── Replica node: reads only (read scaling)
        │   ├── TTL: 300 seconds (configurable per key)
        │   └── Cache HIT: return data immediately (< 1ms)
        │
        └─► RDS MySQL (only on cache MISS or writes)
            ├── Cache MISS: query DB → store in Redis → return data
            └── Writes: write to DB first, then update/invalidate cache

Cache Patterns:
├── Lazy Loading (Cache-Aside): app checks cache first, queries DB on miss
└── Write-Through: every DB write also updates cache (no stale data)
```

---

## 📋 What You'll Learn

- ElastiCache Redis vs Memcached (when to use each)
- Cache-aside (lazy loading) vs write-through vs write-behind patterns
- Cache eviction policies (LRU, LFU, volatile-lru)
- TTL design: how long should data live in cache?
- Redis data structures: strings, hashes, lists, sorted sets
- ElastiCache cluster mode vs non-cluster mode
- Monitoring: CacheHits, CacheMisses, CurrConnections

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Deploy RDS + ElastiCache (30 min)
1. Deploy `cloudformation/caching-stack.yaml`
2. Creates:
   - RDS MySQL with sample product catalogue data
   - ElastiCache Redis cluster (2 nodes) in private subnets
   - EC2 instance (application server) with access to both
3. Note: ElastiCache and RDS must be in the same VPC
4. Security groups: allow port 6379 (Redis) from app SG, 3306 (MySQL) from app SG

### Phase 2: Explore Redis Data Structures (30 min)
1. SSH to the EC2 app server (via Session Manager)
2. Connect to Redis: `redis-cli -h REDIS_ENDPOINT -p 6379`
3. Practice key commands:
```bash
# String (most common for caching)
SET product:123 '{"name":"Widget","price":9.99}' EX 300
GET product:123
TTL product:123

# Hash (structured object)
HSET user:456 name "Alice" email "alice@example.com" tier "premium"
HGET user:456 name
HGETALL user:456

# Sorted set (leaderboard, rate limiting)
ZADD leaderboard 1500 "alice" 1200 "bob" 900 "charlie"
ZRANGE leaderboard 0 -1 WITHSCORES
```

### Phase 3: Implement Lazy Loading Cache Pattern (1 hour)
1. Review `scripts/cache-demo.py` — Python app demonstrating both patterns
2. Run the lazy loading demo:
```bash
python3 cache-demo.py --pattern lazy --product-id 123
```
3. First request: cache MISS → queries RDS → stores in Redis → returns data
4. Second request: cache HIT → returns from Redis (10x faster)
5. Modify the product in RDS directly → cache becomes stale
6. After TTL expires (300s), next request gets fresh data from RDS

### Phase 4: Implement Write-Through Pattern (30 min)
1. Run the write-through demo:
```bash
python3 cache-demo.py --pattern write-through --product-id 456
```
2. Every write goes to RDS first, then immediately updates Redis
3. No stale data, but every write hits both DB and cache
4. Compare the trade-offs with lazy loading

### Phase 5: Benchmark Cache vs No-Cache Performance (45 min)
1. Run the benchmark script:
```bash
python3 cache-demo.py --benchmark --requests 1000
```
2. Measures response time for 1000 requests:
   - Without cache (direct RDS): ~50–200ms per query
   - With cache (Redis HIT): ~1–5ms per query
3. Check CloudWatch metrics: `CacheHits` and `CacheMisses`
4. Calculate your cache hit ratio: HIT / (HIT + MISS)

### Phase 6: Explore Session Store Use Case (20 min)
1. Redis is excellent for storing HTTP sessions
2. Review `scripts/session-demo.py` — stores user sessions in Redis
3. Key insights:
   - Sessions expire automatically (TTL = session timeout)
   - Works across multiple app servers (sticky sessions not needed!)
   - Much faster than database-backed sessions

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/caching-stack.yaml` | RDS + ElastiCache + EC2 stack |
| `scripts/cache-demo.py` | Python: lazy loading vs write-through demo |
| `scripts/session-demo.py` | Python: Redis as session store |
| `scripts/benchmark.sh` | Measure response times with/without cache |
| `docs/redis-vs-memcached.md` | Exam reference: which to choose |

---

## 🧹 Cleanup

1. Delete CloudFormation stack (removes ElastiCache, RDS, EC2)

---

## 📝 Exam Topics Covered

- ✅ ElastiCache Redis vs Memcached
- ✅ Lazy loading (cache-aside) caching pattern
- ✅ Write-through caching pattern
- ✅ Cache TTL and eviction policies
- ✅ Session caching with Redis
- ✅ Read performance improvement with caching
- ✅ ElastiCache replication and high availability
