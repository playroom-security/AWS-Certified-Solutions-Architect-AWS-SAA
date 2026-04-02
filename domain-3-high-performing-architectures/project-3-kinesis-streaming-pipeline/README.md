# Project 3.3 – Kinesis Real-Time Streaming Pipeline

**Domain:** Design High-Performing Architectures  
**Difficulty:** ⭐⭐⭐⭐  
**Estimated Time:** 5–6 hours  
**Approx Cost:** ~$3–8 (Kinesis Data Streams + Firehose; delete after)

---

## 🎯 What You'll Build

A complete real-time event streaming pipeline:
- Kinesis Data Streams ingests clickstream events
- Lambda consumer processes and enriches records in real-time
- Amazon Data Firehose delivers to S3 for batch analytics
- Amazon Athena queries the raw data in S3 (serverless SQL)
- Amazon QuickSight (optional) for dashboards

---

## 🏗️ Architecture Overview

```
Event Producers (EC2 / Lambda / App)
        │ PutRecord / PutRecords API
        ▼
Kinesis Data Streams
├── Stream: saa-clickstream (2 shards)
├── Shard 1: partition key hash 0–50%
├── Shard 2: partition key hash 51–100%
└── Retention: 24 hours (default)
        │
        ├──► Lambda Consumer (real-time processing)
        │    ├── Enrich events (add geo-location from IP)
        │    ├── Filter bot traffic
        │    └── Write alerts to SNS for anomalies
        │
        └──► Amazon Data Firehose
             ├── Buffer: 5 MB or 60 seconds (whichever first)
             ├── Transform: Lambda for JSON → Parquet conversion
             └── Destination: S3 bucket (partitioned by date)
                      │
                      ▼
              Amazon Athena
              └── Serverless SQL on S3 data
                  ├── CREATE TABLE EXTERNAL (on Parquet files)
                  └── Query: top pages, user journeys, etc.
```

---

## 📋 What You'll Learn

- Kinesis Data Streams: shards, partition keys, sequence numbers
- Kinesis vs SQS: when to use streaming vs queuing
- Amazon Data Firehose: buffering, transformation, delivery
- Lambda as a Kinesis stream consumer (event source mapping)
- Athena: serverless SQL on S3
- Data formats: JSON → Parquet (columnar for analytics)

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create Kinesis Data Stream (15 min)
1. Deploy `cloudformation/kinesis-stream.yaml`
2. Creates a Kinesis stream: `saa-clickstream` with 2 shards
3. Understand shard capacity:
   - 1 shard = 1 MB/s write, 2 MB/s read
   - 2 shards = 2 MB/s write, 4 MB/s read
4. In the console, explore the stream monitoring tab

### Phase 2: Produce Events to the Stream (30 min)
1. Run the event producer script:
```bash
python3 scripts/event-producer.py --events 1000 --rate 50
```
2. This sends simulated clickstream events (page views, clicks)
3. Monitor the stream metrics: IncomingRecords, IncomingBytes
4. View records in the Kinesis console data viewer

### Phase 3: Create Lambda Consumer (45 min)
1. Deploy `cloudformation/lambda-consumer.yaml`
2. Creates a Lambda function with Kinesis event source mapping
   - Batch size: 100 records
   - Starting position: LATEST
   - Bisect on error: enabled (retry only failed half of batch)
3. Lambda processes each record, logs enriched data to CloudWatch
4. Test: send events, check Lambda logs in CloudWatch

### Phase 4: Set Up Firehose → S3 (45 min)
1. Deploy `cloudformation/firehose-delivery.yaml`
2. Firehose reads from the same Kinesis stream
3. Configure:
   - Source: Kinesis Data Streams
   - Transform: Lambda function to convert JSON → Parquet
   - Destination: S3 bucket with prefix `year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/`
   - Buffer: 64 MB or 60 seconds
4. Send 5 minutes of events → check S3 for delivered files

### Phase 5: Query with Athena (45 min)
1. In Athena, create a database: `saa_analytics`
2. Create external table pointing to your S3 bucket (Parquet format)
3. Run queries from `athena-queries/`:
```sql
-- Top 10 most visited pages
SELECT page, COUNT(*) as views
FROM saa_analytics.clickstream
WHERE year='2026' AND month='04'
GROUP BY page
ORDER BY views DESC
LIMIT 10;
```
4. Enable Athena query results to S3
5. Explore partitioning: why Parquet is faster and cheaper than JSON

### Phase 6: Compare Kinesis vs SQS (30 min)
Review `docs/kinesis-vs-sqs.md` — this is a high-frequency exam topic!

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/kinesis-stream.yaml` | Kinesis Data Stream |
| `cloudformation/lambda-consumer.yaml` | Lambda + Kinesis event source mapping |
| `cloudformation/firehose-delivery.yaml` | Firehose → S3 pipeline |
| `scripts/event-producer.py` | Generates clickstream events to Kinesis |
| `lambda/stream-processor.py` | Lambda consumer function |
| `lambda/json-to-parquet.py` | Firehose transform Lambda |
| `athena-queries/top-pages.sql` | Sample Athena analytics queries |
| `docs/kinesis-vs-sqs.md` | Exam reference: streaming vs queuing |

---

## 🧹 Cleanup

1. Delete CloudFormation stacks
2. Empty and delete S3 buckets (Firehose destination)
3. Delete Athena database and table

---

## 📝 Exam Topics Covered

- ✅ Kinesis Data Streams: shards, partition keys, throughput
- ✅ Amazon Data Firehose (managed delivery to S3, Redshift, etc.)
- ✅ Kinesis vs SQS decision criteria
- ✅ Lambda as a Kinesis consumer
- ✅ Amazon Athena: serverless SQL on S3
- ✅ Data formats: JSON vs Parquet vs ORC
- ✅ Real-time vs batch data processing
