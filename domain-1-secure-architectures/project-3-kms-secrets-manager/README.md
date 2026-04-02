# Project 1.3 – KMS Encryption + Secrets Manager

**Domain:** Design Secure Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3–4 hours  
**Approx Cost:** ~$1–3 (KMS key costs $1/month; delete after)

---

## 🎯 What You'll Build

A secure data encryption system demonstrating:
- AWS KMS Customer Managed Keys (CMKs) for encrypting S3 data and RDS
- AWS Secrets Manager for storing and auto-rotating database credentials
- Key policies and grants controlling who can use encryption keys
- Encryption at rest and in transit across multiple services

---

## 🏗️ Architecture Overview

```
AWS KMS
├── CMK: AppEncryptionKey
│   ├── Key Policy: allow app-role to use, admin-role to manage
│   └── Automatic Key Rotation: enabled (annually)
│
├── S3 Bucket (SSE-KMS)
│   ├── Server-side encryption with CMK
│   └── Bucket policy: deny uploads without encryption header
│
├── RDS MySQL (encrypted at rest with CMK)
│   └── Encrypted snapshots inherit the key
│
└── Secrets Manager
    ├── Secret: /prod/rds/mysql-credentials
    │   └── Auto-rotation: every 30 days via Lambda
    └── Secret: /prod/app/api-keys
        └── No rotation (manual)
```

---

## 📋 What You'll Learn

- KMS key types: AWS Managed vs Customer Managed vs Customer Provided
- Key policies vs IAM policies for KMS
- Envelope encryption concept
- SSE-S3 vs SSE-KMS vs SSE-C
- Secrets Manager rotation with Lambda
- How to retrieve secrets in application code

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create a Customer Managed Key (30 min)
1. Go to **KMS → Customer managed keys → Create key**
2. Key type: Symmetric, Key usage: Encrypt and decrypt
3. Alias: `alias/saa-study-app-key`
4. Key administrators: your IAM admin user
5. Key users: create an IAM role `AppRole` and add it as a key user
6. Enable automatic key rotation
7. Review the generated key policy JSON — understand the statements

### Phase 2: Encrypt S3 Objects with KMS (45 min)
1. Create an S3 bucket: `saa-kms-demo-<your-account-id>`
2. Enable default encryption: SSE-KMS with your CMK
3. Add bucket policy from `policies/s3-deny-unencrypted.json`
   - This denies any PUT without `x-amz-server-side-encryption` header
4. Upload a test file — verify the encryption details in S3 console
5. Test: try uploading without the encryption header via CLI (should fail)
```bash
# This should FAIL (no encryption header)
aws s3 cp test.txt s3://saa-kms-demo-ACCOUNT/ --no-sse

# This should SUCCEED
aws s3 cp test.txt s3://saa-kms-demo-ACCOUNT/ \
  --sse aws:kms --sse-kms-key-id alias/saa-study-app-key
```

### Phase 3: Create an Encrypted RDS Instance (45 min)
1. Deploy `cloudformation/rds-encrypted.yaml`
2. This creates a MySQL RDS instance with KMS encryption enabled
3. Note: encryption can only be enabled at creation, not after
4. Take a manual snapshot — verify the snapshot is also encrypted
5. Try to copy the snapshot to another region (you must re-encrypt with a regional key)

### Phase 4: Store Credentials in Secrets Manager (45 min)
1. Go to **Secrets Manager → Store a new secret**
2. Secret type: Credentials for RDS
3. Select your RDS instance — it auto-populates the connection info
4. Secret name: `/prod/rds/mysql-credentials`
5. Enable automatic rotation: every 30 days
6. Review the auto-created Lambda rotation function
7. Store a second secret manually: `/prod/app/api-keys`
   - Add key/value pairs: `stripe_key`, `sendgrid_key`

### Phase 5: Retrieve Secrets in Code (30 min)
1. Review `scripts/get-secret.py` — a Python script that retrieves secrets
2. Attach the `SecretsManagerPolicy` from `policies/iam-secrets-policy.json` to your EC2 role
3. Run the script on an EC2 instance to retrieve the database password dynamically
4. Understand why this is better than hardcoding credentials in code or env vars

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/kms-key.yaml` | Creates CMK with key policy |
| `cloudformation/rds-encrypted.yaml` | MySQL RDS with KMS encryption |
| `policies/s3-deny-unencrypted.json` | S3 bucket policy requiring KMS encryption |
| `policies/iam-secrets-policy.json` | IAM policy to allow secret retrieval |
| `scripts/get-secret.py` | Python script to retrieve secrets dynamically |
| `scripts/encrypt-test.sh` | CLI commands to test KMS encryption |

---

## 🧹 Cleanup

1. Delete RDS instance (no final snapshot needed for lab)
2. Schedule CMK deletion (7-day minimum waiting period)
3. Delete Secrets Manager secrets (with 7-day recovery window or force delete)
4. Empty and delete S3 bucket

---

## 📝 Exam Topics Covered

- ✅ AWS KMS Customer Managed Keys
- ✅ Key policies and grants
- ✅ Automatic key rotation
- ✅ S3 encryption: SSE-KMS
- ✅ RDS encryption at rest
- ✅ AWS Secrets Manager and secret rotation
- ✅ Encryption at rest vs in transit
- ✅ Envelope encryption
