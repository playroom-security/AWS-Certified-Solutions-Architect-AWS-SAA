# Kinesis vs SQS – Decision Guide
## SAA Study Project 3.3 – High-Frequency Exam Topic

---

## Quick Answer

| Question | Answer |
|---|---|
| Need **multiple consumers** read the **same** messages? | **Kinesis** |
| Need to process events **in order** within a partition? | **Kinesis** |
| Need **real-time** analytics on a stream? | **Kinesis** |
| Need simple **decoupled task queue**? | **SQS** |
| Need **exactly-once** processing? | **SQS FIFO** |
| Consumers are **independent services** needing own copy? | **SNS + SQS fan-out** |

---

## Detailed Comparison

| Feature | Kinesis Data Streams | SQS Standard | SQS FIFO |
|---|---|---|---|
| **Message ordering** | Per shard (partition key) | Best effort | Strict FIFO ✅ |
| **Multiple consumers** | Yes — all read full stream | No — one consumer per message | No |
| **Message retention** | 24hr (up to 365 days) | 4 days (up to 14 days) | 4 days |
| **Delivery guarantee** | At-least-once | At-least-once | Exactly-once |
| **Throughput** | 1 MB/s per shard | Nearly unlimited | 300–3000 TPS |
| **Replay messages** | Yes ✅ (within retention) | No — deleted after consume | No |
| **Real-time analytics** | Yes ✅ | No | No |
| **Scaling** | Manual (add shards) | Automatic | Automatic |
| **Pricing model** | Per shard-hour | Per request | Per request |

---

## When to Use Kinesis Data Streams
- Real-time dashboards and monitoring
- Clickstream and telemetry analytics
- Multiple independent services consuming the same event stream
- Log aggregation and processing
- IoT sensor data pipelines
- You need to **replay** past events (consumers can rewind)

## When to Use SQS Standard
- Task distribution between workers (one task → one worker)
- Decoupling microservices that process independently
- Background job processing (image resize, email send)
- You don't need order guarantees
- High-throughput workloads at low cost

## When to Use SQS FIFO
- Financial transaction processing (order matters!)
- Inventory management (debit must happen before credit)
- Order processing systems
- Any workflow where strict sequencing is critical
- Note: limited to 3,000 TPS with batching

---

## Kinesis Family — Know the Differences

| Service | Purpose |
|---|---|
| **Kinesis Data Streams** | Build custom real-time apps; you write the consumer code |
| **Amazon Data Firehose** | Fully managed delivery to S3, Redshift, OpenSearch; no consumer code |
| **Kinesis Video Streams** | Stream video from devices to AWS for ML/playback |

---

## Common Exam Scenarios

**"Company needs to process stock trades in strict order and ensure no duplicates"**
→ SQS FIFO (strict order, exactly-once)

**"Real-time analytics dashboard showing website clickstream data"**
→ Kinesis Data Streams → Lambda or KDA (multiple consumers, real-time)

**"Load clickstream data into S3 for batch analytics, no custom code"**
→ Amazon Data Firehose (managed, buffers and delivers to S3)

**"Decouple order service from fulfilment service"**
→ SQS Standard (simple decoupling, one consumer per message)

**"Multiple teams need to consume the same event stream independently"**
→ Kinesis Data Streams (multiple consumer groups, replay capability)

**"Fan-out: one event must trigger both an email AND an SMS"**
→ SNS topic with SQS subscribers (fan-out pattern)
