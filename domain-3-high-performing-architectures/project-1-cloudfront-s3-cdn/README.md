# Project 3.1 – CloudFront + S3 Static Website CDN

**Domain:** Design High-Performing Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3–4 hours  
**Approx Cost:** Free Tier eligible (1 TB/month CloudFront transfer free for 12 months)

---

## 🎯 What You'll Build

A globally distributed static website with:
- S3 as the origin (private — no public access)
- CloudFront CDN caching content at 400+ edge locations worldwide
- HTTPS enforced via ACM (free SSL certificate)
- Custom domain with Route 53
- CloudFront Functions for URL rewriting
- Origin Access Control (OAC) — S3 only serves via CloudFront

---

## 🏗️ Architecture Overview

```
User (anywhere in the world)
        │
        ▼ HTTPS request to cdn.saa-study.com
Amazon Route 53
        │ ALIAS record → CloudFront Distribution
        ▼
Amazon CloudFront (edge location — nearest to user)
├── Cache HIT: serve from edge (< 5ms latency)
├── Cache MISS: fetch from S3 origin, cache at edge
├── HTTPS only (HTTP → 301 redirect to HTTPS)
├── ACM Certificate: *.saa-study.com
├── CloudFront Function: rewrite /blog → /blog/index.html
└── Geo-restriction: optional (block specific countries)
        │
        ▼ (only on cache miss)
Amazon S3 (private bucket — no public access!)
├── Origin Access Control (OAC) — CloudFront only
├── Static files: index.html, CSS, JS, images
└── Versioned uploads for safe deployments
```

---

## 📋 What You'll Learn

- CloudFront distributions, behaviours, and cache policies
- S3 Origin Access Control (OAC) — the modern replacement for OAI
- ACM certificate provisioning for CloudFront (must be in us-east-1!)
- Cache invalidation: when and how to use it
- CloudFront Functions vs Lambda@Edge
- TTL settings and Cache-Control headers
- Geo-restriction and signed URLs for private content

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create the S3 Origin (20 min)
1. Create bucket: `saa-cf-origin-ACCOUNT_ID` in us-east-1
2. **Block all public access** (leave everything blocked — CloudFront uses OAC)
3. Enable versioning (good practice for safe deployments)
4. Upload sample website files from `website/` directory:
```bash
aws s3 sync website/ s3://saa-cf-origin-ACCOUNT_ID/
```
5. Do NOT set bucket for static website hosting — we use CloudFront for that

### Phase 2: Create ACM Certificate (15 min)
1. Go to **ACM in us-east-1** (CloudFront requires us-east-1 certificates!)
2. Request a public certificate for: `*.saa-study.com` and `saa-study.com`
3. Validation: DNS (add the CNAME record to Route 53)
4. Wait for certificate status: Issued (~2 minutes with Route 53)

### Phase 3: Create CloudFront Distribution (30 min)
1. Deploy `cloudformation/cloudfront-distribution.yaml`
2. Review key settings in the console after deployment:
   - **Origin**: S3 bucket with OAC (not public)
   - **Default cache behaviour**: redirect HTTP → HTTPS, GET/HEAD only
   - **Cache policy**: Managed-CachingOptimized
   - **Price class**: Use only North America and Europe (cheaper)
   - **Alternate domain**: `cdn.saa-study.com`
   - **Certificate**: your ACM certificate
3. Note the CloudFront domain name (e.g., `dxxxxxxxx.cloudfront.net`)

### Phase 4: Configure Origin Access Control (15 min)
1. CloudFront automatically creates the OAC policy in the wizard
2. Check S3 bucket policy was updated to allow only CloudFront to read:
```json
{
  "Principal": {"Service": "cloudfront.amazonaws.com"},
  "Condition": {"StringEquals": {
    "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DIST_ID"
  }}
}
```
3. Test: try accessing the S3 URL directly — should get 403 Access Denied
4. Test: access via CloudFront URL — should work

### Phase 5: Add CloudFront Function (30 min)
1. Create a CloudFront Function from `cloudfront-functions/url-rewrite.js`
2. This rewrites `/blog` → `/blog/index.html` so clean URLs work
3. Associate the function with the Default (*) cache behaviour
4. Publish the function and test

### Phase 6: Test Caching and Invalidation (30 min)
1. Check response headers: `curl -I https://cdn.saa-study.com/`
   - Look for: `X-Cache: Hit from cloudfront` vs `Miss from cloudfront`
   - Look for: `Age: 3600` (seconds since cached at edge)
2. Update `index.html` and re-upload to S3
3. Request the page — still shows old version (cached!)
4. Create an invalidation: `aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"`
5. Request again — now shows new version

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `website/` | Sample static website (HTML, CSS, JS) |
| `cloudformation/cloudfront-distribution.yaml` | CloudFront + S3 + OAC stack |
| `cloudfront-functions/url-rewrite.js` | URL rewriting CloudFront Function |
| `scripts/deploy-website.sh` | S3 sync + cache invalidation in one command |
| `docs/cloudfront-cheatsheet.md` | CloudFront exam reference |

---

## 🧹 Cleanup

1. Delete CloudFormation stack
2. Empty and delete S3 bucket
3. Delete ACM certificate
4. Delete Route 53 records

---

## 📝 Exam Topics Covered

- ✅ CloudFront distributions, behaviours, and cache policies
- ✅ S3 Origin Access Control (OAC)
- ✅ ACM certificates and HTTPS enforcement
- ✅ Cache invalidation
- ✅ CloudFront Functions vs Lambda@Edge
- ✅ Edge caching and latency reduction
- ✅ Price classes and geo-restriction
