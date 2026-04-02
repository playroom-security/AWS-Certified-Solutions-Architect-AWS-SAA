#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 3.1 - Deploy Website + Invalidate CloudFront Cache
# ─────────────────────────────────────────────────────────────────────────────

BUCKET_NAME="saa-cf-origin-YOUR_ACCOUNT_ID"
DISTRIBUTION_ID="YOUR_CLOUDFRONT_DISTRIBUTION_ID"
WEBSITE_DIR="./website"

echo "================================================"
echo "  Deploy Static Site to S3 + CloudFront"
echo "================================================"

echo ""
echo "[1/3] Syncing files to S3..."
aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_NAME/" \
  --delete \
  --cache-control "max-age=86400, public"

# HTML files should not be cached long (so updates propagate quickly)
aws s3 cp "$WEBSITE_DIR/index.html" "s3://$BUCKET_NAME/index.html" \
  --cache-control "max-age=60, no-cache" \
  --content-type "text/html"

echo "✅ S3 sync complete"

echo ""
echo "[2/3] Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "✅ Invalidation created: $INVALIDATION_ID"

echo ""
echo "[3/3] Waiting for invalidation to complete..."
aws cloudfront wait invalidation-completed \
  --distribution-id "$DISTRIBUTION_ID" \
  --id "$INVALIDATION_ID"

echo "✅ Invalidation complete — new content is live!"
echo ""
echo "Your site: https://cdn.saa-study.com"
echo ""
echo "Test cache headers:"
echo "  curl -I https://cdn.saa-study.com/"
echo "  Look for: X-Cache: Hit from cloudfront"
