# Project 4.2 – S3 Lifecycle Policies + Glacier Archival

**Domain:** Design Cost-Optimized Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3–4 hours  
**Approx Cost:** Free Tier eligible (S3 storage minimal; Glacier very cheap)

---

## 🎯 What You'll Build

A cost-optimised S3 storage tiering system:
- S3 Intelligent-Tiering for unpredictable access patterns
- Lifecycle rules: auto-transition objects through storage classes
- S3 Glacier Instant Retrieval for archives with occasional access
- S3 Glacier Deep Archive for long-term compliance data (cheapest storage)
- S3 Storage Lens for cost visibility across buckets

---

## 🏗️ Architecture Overview

```
S3 Storage Classes (cost per GB/month, approximate):

S3 Standard ($0.023)          ← Active data, frequent access
      │  after 30 days
      ▼
S3 Standard-IA ($0.0125)      ← Infrequent access (min 128 KB, 30-day min)
      │  after 60 days
      ▼
S3 Glacier Instant ($0.004)   ← Archives, retrieval in milliseconds
      │  after 180 days
      ▼
S3 Glacier Flexible ($0.0036) ← Long-term, retrieve in minutes/hours
      │  after 365 days
      ▼
S3 Glacier Deep Archive ($0.00099) ← Cheapest, 12-hour retrieval, 7-10yr retention

Lifecycle Rules:
├── Rule 1: application-logs/ → S3-IA after 30d, Glacier after 90d, delete after 365d
├── Rule 2: user-uploads/    → Intelligent-Tiering (auto)
└── Rule 3: compliance-data/ → Glacier Deep Archive after 90d, delete after 7 years
```

---

## 📋 What You'll Learn

- All S3 storage classes and their trade-offs (cost/retrieval time/minimum duration)
- S3 Lifecycle rules: transitions and expirations
- S3 Intelligent-Tiering: automatic tier movement
- Glacier retrieval options: Expedited, Standard, Bulk
- S3 Replication: cross-region (CRR) and same-region (SRR)
- S3 Storage Lens and Cost Analysis
- Requester Pays buckets

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create the Bucket with Storage Classes in Mind (20 min)
1. Deploy `cloudformation/s3-lifecycle.yaml`
2. Creates an S3 bucket with:
   - Versioning enabled
   - 3 lifecycle rules pre-configured
   - S3 Storage Lens enabled
3. Upload sample files to different prefixes:
```bash
# Application logs
aws s3 cp sample-log.txt s3://saa-lifecycle-ACCOUNT/application-logs/2024/01/app.log

# User uploads
aws s3 cp sample-image.jpg s3://saa-lifecycle-ACCOUNT/user-uploads/photo.jpg

# Compliance data
aws s3 cp sample-report.pdf s3://saa-lifecycle-ACCOUNT/compliance-data/q1-report.pdf
```

### Phase 2: Review Lifecycle Rules in Console (30 min)
1. Open the S3 bucket → Management → Lifecycle rules
2. Review each rule — understand:
   - **Transition actions**: move objects between storage classes
   - **Expiration actions**: delete objects after N days
   - **Filter**: prefix or tag-based (e.g., only affect `application-logs/`)
3. Note: transitions have minimum duration requirements:
   - S3-IA: minimum 30 days in current class
   - Glacier: minimum 90 days

### Phase 3: Enable S3 Intelligent-Tiering (20 min)
1. For the `user-uploads/` prefix, enable Intelligent-Tiering:
```bash
aws s3api put-bucket-intelligent-tiering-configuration \
  --bucket saa-lifecycle-ACCOUNT \
  --id UserUploadsIT \
  --intelligent-tiering-configuration file://intelligent-tiering-config.json
```
2. Review `configs/intelligent-tiering-config.json`
3. Intelligent-Tiering monitors access patterns — no management needed
4. Objects not accessed for 30 days → moved to Infrequent Access tier automatically

### Phase 4: Archive to Glacier and Practice Retrieval (45 min)
1. Manually transition an object to Glacier:
```bash
aws s3 cp s3://saa-lifecycle-ACCOUNT/compliance-data/q1-report.pdf \
  s3://saa-lifecycle-ACCOUNT/compliance-data/q1-report.pdf \
  --storage-class GLACIER
```
2. Check the object in console — note it shows as Glacier storage class
3. Initiate a retrieval (this is important exam knowledge!):
```bash
# Standard retrieval (3-5 hours, cheapest)
aws s3api restore-object \
  --bucket saa-lifecycle-ACCOUNT \
  --key compliance-data/q1-report.pdf \
  --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Standard"}}'

# Expedited retrieval (1-5 minutes, costs more)
aws s3api restore-object \
  --bucket saa-lifecycle-ACCOUNT \
  --key compliance-data/q1-report.pdf \
  --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Expedited"}}'
```
4. Check restore status: `aws s3api head-object --bucket ... --key ...`

### Phase 5: Cost Comparison Exercise (30 min)
Review `docs/storage-class-comparison.md` and complete the cost worksheet:
- Given: 1 TB of data, accessed first month, then rarely after 90 days
- Calculate monthly cost for: Standard vs IA + lifecycle vs Intelligent-Tiering
- This type of cost calculation appears on the exam!

### Phase 6: S3 Cross-Region Replication (20 min)
1. Enable CRR for the `compliance-data/` prefix to a second bucket in us-west-2
2. Use case: compliance, disaster recovery, reduce latency for global teams
3. Review IAM role required for replication
4. Note: CRR only replicates NEW objects, not existing ones

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/s3-lifecycle.yaml` | S3 bucket with lifecycle rules |
| `configs/intelligent-tiering-config.json` | Intelligent-Tiering configuration |
| `configs/replication-config.json` | Cross-region replication config |
| `scripts/upload-test-files.sh` | Upload sample files to all prefixes |
| `scripts/restore-from-glacier.sh` | Glacier restore with status check |
| `docs/storage-class-comparison.md` | All S3 tiers: cost, retrieval, use cases |

---

## 🧹 Cleanup

1. Empty all S3 buckets (including versioned objects and delete markers)
2. Delete CloudFormation stacks

---

## 📝 Exam Topics Covered

- ✅ All S3 storage classes and trade-offs
- ✅ S3 Lifecycle rules (transitions and expirations)
- ✅ S3 Intelligent-Tiering
- ✅ S3 Glacier retrieval options (Expedited, Standard, Bulk)
- ✅ S3 Cross-Region Replication
- ✅ S3 versioning
- ✅ Minimum storage duration charges
