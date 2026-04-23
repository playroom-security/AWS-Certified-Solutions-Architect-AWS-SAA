#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 2.4 - Build and Push All Microservice Images to ECR
#
# Prerequisites:
#   - Docker is running locally
#   - AWS CLI is configured with credentials
#   - ECR repositories already created (see Phase 1 in README)
#
# Usage:
#   chmod +x scripts/build-push-all.sh
#   ./scripts/build-push-all.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e  # Exit immediately on any error

# ── Configuration — update ACCOUNT_ID ────────────────────────────────────────
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
SERVICES=("users" "products" "orders")
TAG="latest"

echo "============================================================"
echo "  SAA Study - Build & Push All Microservice Images to ECR"
echo "  Account: $ACCOUNT_ID"
echo "  Region:  $REGION"
echo "  ECR:     $ECR_BASE"
echo "============================================================"

# ── Step 1: Authenticate Docker to ECR ───────────────────────────────────────
echo ""
echo "[1/4] Authenticating Docker to ECR..."
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ECR_BASE"
echo "✅ Docker authenticated to ECR"

# ── Step 2: Ensure ECR repositories exist ────────────────────────────────────
echo ""
echo "[2/4] Ensuring ECR repositories exist..."
for SVC in "${SERVICES[@]}"; do
  REPO_NAME="saa-${SVC}-service"
  if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" \
      > /dev/null 2>&1; then
    echo "  ✅ Repository exists: $REPO_NAME"
  else
    echo "  Creating repository: $REPO_NAME"
    aws ecr create-repository \
      --repository-name "$REPO_NAME" \
      --region "$REGION" \
      --image-scanning-configuration scanOnPush=true \
      --tags Key=Project,Value=SAA-Study
    echo "  ✅ Created: $REPO_NAME"
  fi
done

# ── Step 3: Build all images ──────────────────────────────────────────────────
echo ""
echo "[3/4] Building Docker images..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

BUILD_ERRORS=0
for SVC in "${SERVICES[@]}"; do
  SERVICE_DIR="${PROJECT_ROOT}/services/${SVC}-service"
  IMAGE_NAME="saa-${SVC}-service"
  ECR_URI="${ECR_BASE}/${IMAGE_NAME}:${TAG}"

  echo ""
  echo "  Building ${IMAGE_NAME}..."
  if docker build \
      --platform linux/amd64 \
      -t "${IMAGE_NAME}:${TAG}" \
      -t "${ECR_URI}" \
      "${SERVICE_DIR}"; then
    echo "  ✅ Built: ${IMAGE_NAME}:${TAG}"
  else
    echo "  ❌ Build FAILED for ${IMAGE_NAME}"
    BUILD_ERRORS=$((BUILD_ERRORS + 1))
  fi
done

if [ "$BUILD_ERRORS" -gt 0 ]; then
  echo ""
  echo "❌ $BUILD_ERRORS build(s) failed. Fix errors above before pushing."
  exit 1
fi

# ── Step 4: Push all images to ECR ───────────────────────────────────────────
echo ""
echo "[4/4] Pushing images to ECR..."

for SVC in "${SERVICES[@]}"; do
  IMAGE_NAME="saa-${SVC}-service"
  ECR_URI="${ECR_BASE}/${IMAGE_NAME}:${TAG}"

  echo ""
  echo "  Pushing ${IMAGE_NAME} → ECR..."
  docker push "${ECR_URI}"
  echo "  ✅ Pushed: ${ECR_URI}"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  ✅ ALL IMAGES BUILT AND PUSHED SUCCESSFULLY"
echo ""
echo "  ECR Image URIs (copy into task-definitions.yaml):"
for SVC in "${SERVICES[@]}"; do
  echo "  ${SVC}: ${ECR_BASE}/saa-${SVC}-service:${TAG}"
done
echo ""
echo "  Next step: Deploy CloudFormation stacks"
echo "    aws cloudformation deploy \\"
echo "      --template-file cloudformation/task-definitions.yaml \\"
echo "      --stack-name saa-ecs-task-defs \\"
echo "      --capabilities CAPABILITY_NAMED_IAM"
echo "============================================================"