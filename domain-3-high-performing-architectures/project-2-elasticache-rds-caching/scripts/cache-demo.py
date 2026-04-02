"""
SAA Study Project 3.2 - ElastiCache Caching Patterns Demo
Demonstrates Lazy Loading and Write-Through patterns.

Install dependencies:
  pip install redis pymysql boto3

Usage:
  python3 cache-demo.py --pattern lazy --product-id 123
  python3 cache-demo.py --pattern write-through --product-id 456
  python3 cache-demo.py --benchmark --requests 1000
"""

import argparse
import json
import time
import redis
import pymysql
import os

# ── Config ────────────────────────────────────────────────────────────────────
REDIS_HOST = os.environ.get("REDIS_HOST", "your-redis-endpoint.cache.amazonaws.com")
REDIS_PORT = 6379
REDIS_TTL = 300  # 5 minutes

DB_HOST = os.environ.get("DB_HOST", "your-rds-endpoint.rds.amazonaws.com")
DB_USER = os.environ.get("DB_USER", "admin")
DB_PASS = os.environ.get("DB_PASS", "password")
DB_NAME = os.environ.get("DB_NAME", "products")


def get_redis():
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


def get_db():
    return pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS,
                           database=DB_NAME, cursorclass=pymysql.cursors.DictCursor)


# ── PATTERN 1: Lazy Loading (Cache-Aside) ─────────────────────────────────────

def get_product_lazy(product_id: int) -> dict:
    """
    Lazy Loading pattern:
    1. Check cache first
    2. On MISS: query DB, store in cache, return
    3. On HIT: return from cache (fast!)
    """
    r = get_redis()
    cache_key = f"product:{product_id}"

    # Step 1: Try cache
    cached = r.get(cache_key)
    if cached:
        print(f"  ✅ Cache HIT for product:{product_id}")
        return json.loads(cached)

    # Step 2: Cache miss — query database
    print(f"  ❌ Cache MISS for product:{product_id} — querying RDS...")
    start = time.time()
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
            product = cursor.fetchone()
    db_time = (time.time() - start) * 1000
    print(f"  🗄️  RDS query took {db_time:.1f}ms")

    if not product:
        return None

    # Step 3: Store in cache with TTL
    r.setex(cache_key, REDIS_TTL, json.dumps(product))
    print(f"  💾 Stored in Redis with TTL={REDIS_TTL}s")

    return product


# ── PATTERN 2: Write-Through ─────────────────────────────────────────────────

def update_product_write_through(product_id: int, data: dict):
    """
    Write-Through pattern:
    1. Write to DB first (source of truth)
    2. Immediately update cache
    → No stale data, but every write hits both DB and cache
    """
    print(f"  📝 Write-Through update for product:{product_id}")

    # Step 1: Write to DB
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "UPDATE products SET name=%s, price=%s WHERE id=%s",
                (data["name"], data["price"], product_id)
            )
        conn.commit()
    print("  ✅ Written to RDS")

    # Step 2: Update cache immediately
    r = get_redis()
    cache_key = f"product:{product_id}"
    r.setex(cache_key, REDIS_TTL, json.dumps(data))
    print("  ✅ Cache updated — no stale data!")


# ── BENCHMARK ────────────────────────────────────────────────────────────────

def run_benchmark(num_requests: int = 100):
    """Compare response times: direct RDS vs Redis cache."""
    print(f"\n{'='*60}")
    print(f"  BENCHMARK: {num_requests} requests")
    print(f"{'='*60}")

    product_id = 1

    # Warm up the cache
    get_product_lazy(product_id)

    # Benchmark cache hits
    cache_times = []
    for _ in range(num_requests):
        start = time.time()
        get_product_lazy(product_id)
        cache_times.append((time.time() - start) * 1000)

    # Benchmark direct DB (no cache)
    db_times = []
    for _ in range(min(50, num_requests)):  # fewer DB calls to avoid load
        start = time.time()
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
                cursor.fetchone()
        db_times.append((time.time() - start) * 1000)

    print(f"\n📊 Results:")
    print(f"  Redis Cache  — avg: {sum(cache_times)/len(cache_times):.2f}ms | "
          f"min: {min(cache_times):.2f}ms | max: {max(cache_times):.2f}ms")
    print(f"  RDS Direct   — avg: {sum(db_times)/len(db_times):.2f}ms | "
          f"min: {min(db_times):.2f}ms | max: {max(db_times):.2f}ms")
    speedup = (sum(db_times)/len(db_times)) / (sum(cache_times)/len(cache_times))
    print(f"\n  🚀 Cache is ~{speedup:.0f}x faster than direct DB queries!")
    print(f"{'='*60}\n")


# ── MAIN ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ElastiCache caching demo")
    parser.add_argument("--pattern", choices=["lazy", "write-through"], help="Caching pattern to demo")
    parser.add_argument("--product-id", type=int, default=1)
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--requests", type=int, default=100)
    args = parser.parse_args()

    if args.benchmark:
        run_benchmark(args.requests)
    elif args.pattern == "lazy":
        print("\n📖 LAZY LOADING (Cache-Aside) Demo")
        print("─" * 40)
        print("Request 1 (expect MISS):")
        product = get_product_lazy(args.product_id)
        print(f"  Result: {product}")
        print("\nRequest 2 (expect HIT):")
        product = get_product_lazy(args.product_id)
        print(f"  Result: {product}")
    elif args.pattern == "write-through":
        print("\n✍️  WRITE-THROUGH Demo")
        print("─" * 40)
        update_product_write_through(args.product_id, {"name": "Updated Widget", "price": 19.99})
        print("\nReading updated product (should be cache HIT):")
        product = get_product_lazy(args.product_id)
        print(f"  Result: {product}")
