# S3 Storage Class Comparison
## SAA Study Project 4.2 – Key Exam Reference

---

## Storage Classes at a Glance

| Storage Class | Use Case | Retrieval | Cost/GB/mo | Min Duration | Min Size |
|---|---|---|---|---|---|
| **S3 Standard** | Frequently accessed | Milliseconds | $0.023 | None | None |
| **S3 Intelligent-Tiering** | Unknown/changing access | Milliseconds | $0.023 (frequent) $0.0125 (infrequent) | None | None |
| **S3 Standard-IA** | Infrequently accessed, rapid retrieval | Milliseconds | $0.0125 | 30 days | 128 KB |
| **S3 One Zone-IA** | Infrequent, non-critical, single AZ | Milliseconds | $0.01 | 30 days | 128 KB |
| **S3 Glacier Instant Retrieval** | Archives, quarterly access | Milliseconds | $0.004 | 90 days | 128 KB |
| **S3 Glacier Flexible Retrieval** | Archives, annual access | Minutes–hours | $0.0036 | 90 days | None |
| **S3 Glacier Deep Archive** | Long-term compliance (7–10 yrs) | 12 hours | $0.00099 | 180 days | None |

---

## Glacier Retrieval Options

| Tier | Time | Cost | Use When |
|---|---|---|---|
| **Expedited** | 1–5 minutes | Highest | Urgent access, SLA requirement |
| **Standard** | 3–5 hours | Medium | Default, planned retrieval |
| **Bulk** | 5–12 hours | Lowest | Non-urgent, large volume restores |

**Note:** Deep Archive retrieval options are Standard (12hr) and Bulk (48hr) only — no Expedited.

---

## Decision Tree

```
Is data accessed frequently (weekly)?
├── YES → S3 Standard
└── NO → Is access pattern predictable?
          ├── NO  → S3 Intelligent-Tiering (auto-manages tiers)
          └── YES → Is retrieval time critical (milliseconds)?
                    ├── YES → S3 Standard-IA or Glacier Instant Retrieval
                    └── NO  → How long until retrieval?
                              ├── Minutes OK → Glacier Flexible Retrieval
                              └── Hours OK   → Glacier Deep Archive (cheapest!)
```

---

## Lifecycle Transition Timing Constraints (Exam Critical!)

Minimum time an object must stay in a class before transitioning:
- Standard → Standard-IA: **30 days minimum**
- Standard → Glacier Instant: **90 days minimum**
- Any class → Glacier Flexible: **90 days minimum**
- Any class → Glacier Deep Archive: **180 days minimum**

**Minimum storage charge duration:**
- Standard-IA, One Zone-IA: charged for minimum **30 days**
- Glacier Instant: charged for minimum **90 days**
- Glacier Flexible: charged for minimum **90 days**
- Glacier Deep Archive: charged for minimum **180 days**

Example: If you store 1 GB in Standard-IA for just 10 days, you still pay for 30 days.

---

## S3 Replication

| Type | Abbreviation | Copies To | Use Case |
|---|---|---|---|
| Cross-Region Replication | CRR | Different AWS region | DR, latency, compliance |
| Same-Region Replication | SRR | Same region, different bucket | Log aggregation, dev/prod separation |

**Requirements for replication:**
- Source and destination buckets must have versioning enabled
- IAM role with permissions to read source and write destination
- Only NEW objects replicate; existing objects need S3 Batch Operations

---

## Cost Optimisation Tips

1. **Enable Lifecycle rules** — biggest wins come from automatically moving old data to IA/Glacier
2. **Use Intelligent-Tiering** for data with unpredictable access patterns
3. **Use Glacier Deep Archive** for compliance data you keep for years
4. **Enable S3 Storage Lens** to identify buckets with no lifecycle rules
5. **S3 Requester Pays**: shift data transfer costs to the requester (useful for data sharing)
6. **Compress data** before storing (smaller objects = lower cost)
7. **Multipart upload** for objects > 100 MB (required above 5 GB)

---

## Exam Scenarios

**"Keep logs for 1 year, rarely accessed after 30 days, delete after 365 days"**
→ Lifecycle: Standard → Standard-IA (day 30) → Glacier (day 90) → Delete (day 365)

**"Medical images accessed heavily in first month, then quarterly"**
→ S3 Intelligent-Tiering (automatic, no management overhead)

**"7-year compliance archive, never accessed unless audit"**
→ S3 Glacier Deep Archive (cheapest, 12-hour retrieval acceptable)

**"Static website assets accessed globally, minimize latency"**
→ S3 Standard + CloudFront (not a storage class question — it's a distribution question)

**"Replicate S3 data to another region for disaster recovery"**
→ S3 Cross-Region Replication (CRR) with versioning enabled
