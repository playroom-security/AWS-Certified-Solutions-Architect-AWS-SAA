#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# SAA Study Project 1.4 - Cognito Authentication Flow
# Complete CLI walkthrough: sign-up → confirm → sign-in → call API
#
# Usage: Fill in the variables below, then run each section manually
#        so you can observe each step and its output.
#
# Get USER_POOL_ID and CLIENT_ID from the CloudFormation stack outputs:
#   aws cloudformation describe-stacks --stack-name <your-stack-name> \
#     --query "Stacks[0].Outputs"
# ─────────────────────────────────────────────────────────────────────────────

USER_POOL_ID="us-east-1_XXXXXXXXX"        # From CloudFormation output: UserPoolId
CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxx"     # From CloudFormation output: UserPoolClientId
API_ENDPOINT="https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod"  # ApiEndpoint output
TEST_EMAIL="testuser@example.com"
TEST_PASSWORD="Test@Password123"
ADMIN_EMAIL="adminuser@example.com"
ADMIN_PASSWORD="Admin@Password123"

# ──────────────────────────────────────────────────────────────────────────────
echo "============================================================"
echo "  SECTION 1: Register a standard user"
echo "============================================================"

# Sign up (self-registration)
echo "[1.1] Signing up $TEST_EMAIL..."
aws cognito-idp sign-up \
  --client-id "$CLIENT_ID" \
  --username "$TEST_EMAIL" \
  --password "$TEST_PASSWORD" \
  --user-attributes Name=email,Value="$TEST_EMAIL"

# Admin-confirm the user (skips the email verification step for lab speed)
echo "[1.2] Admin-confirming user (bypasses email verification)..."
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id "$USER_POOL_ID" \
  --username "$TEST_EMAIL"

echo "✅ User $TEST_EMAIL registered and confirmed"

# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SECTION 2: Sign in and inspect the JWT tokens"
echo "============================================================"

echo "[2.1] Authenticating $TEST_EMAIL..."
AUTH_RESULT=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME="$TEST_EMAIL",PASSWORD="$TEST_PASSWORD" \
  --query "AuthenticationResult")

ID_TOKEN=$(echo "$AUTH_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['IdToken'])")
ACCESS_TOKEN=$(echo "$AUTH_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessToken'])")
REFRESH_TOKEN=$(echo "$AUTH_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['RefreshToken'])")

echo "✅ Signed in successfully"
echo ""
echo "[2.2] Decoding ID Token payload (middle section between dots)..."
# JWT = header.payload.signature — decode the payload (base64)
echo "$ID_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | python3 -m json.tool
echo ""
echo "Key claims to notice:"
echo "  - 'sub'              = unique user ID (never changes)"
echo "  - 'email'            = user's email address"
echo "  - 'cognito:groups'   = empty (not in any group yet)"
echo "  - 'token_use'        = 'id' (this is the ID token)"
echo "  - 'exp'              = expiry Unix timestamp"

# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SECTION 3: Call protected API endpoints"
echo "============================================================"

echo "[3.1] Calling GET /profile with valid token (expect 200)..."
curl -s -w "\nHTTP Status: %{http_code}\n" \
  -H "Authorization: Bearer $ID_TOKEN" \
  "$API_ENDPOINT/profile" | python3 -m json.tool

echo ""
echo "[3.2] Calling GET /profile WITHOUT token (expect 401 Unauthorized)..."
curl -s -w "\nHTTP Status: %{http_code}\n" \
  "$API_ENDPOINT/profile"

echo ""
echo "[3.3] Calling GET /admin as standard user (expect 403 Forbidden)..."
curl -s -w "\nHTTP Status: %{http_code}\n" \
  -H "Authorization: Bearer $ID_TOKEN" \
  "$API_ENDPOINT/admin" | python3 -m json.tool

# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SECTION 4: Group-based access control"
echo "============================================================"

echo "[4.1] Creating an admin user..."
aws cognito-idp sign-up \
  --client-id "$CLIENT_ID" \
  --username "$ADMIN_EMAIL" \
  --password "$ADMIN_PASSWORD" \
  --user-attributes Name=email,Value="$ADMIN_EMAIL"

aws cognito-idp admin-confirm-sign-up \
  --user-pool-id "$USER_POOL_ID" \
  --username "$ADMIN_EMAIL"

echo "[4.2] Adding admin user to the Admins group..."
aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username "$ADMIN_EMAIL" \
  --group-name Admins

echo "✅ $ADMIN_EMAIL added to Admins group"

echo ""
echo "[4.3] Signing in as admin (new token will include group claim)..."
ADMIN_AUTH=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME="$ADMIN_EMAIL",PASSWORD="$ADMIN_PASSWORD" \
  --query "AuthenticationResult.IdToken" \
  --output text)

echo "[4.4] Decoding admin token — notice 'cognito:groups' now includes 'Admins'..."
echo "$ADMIN_AUTH" | cut -d. -f2 | base64 -d 2>/dev/null | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('Groups:', d.get('cognito:groups','none'))"

echo ""
echo "[4.5] Calling GET /admin as admin user (expect 200 Welcome)..."
curl -s -w "\nHTTP Status: %{http_code}\n" \
  -H "Authorization: Bearer $ADMIN_AUTH" \
  "$API_ENDPOINT/admin" | python3 -m json.tool

# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SECTION 5: Token refresh"
echo "============================================================"

echo "[5.1] Refreshing the ID token using the Refresh Token..."
NEW_TOKENS=$(aws cognito-idp initiate-auth \
  --auth-flow REFRESH_TOKEN_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters REFRESH_TOKEN="$REFRESH_TOKEN" \
  --query "AuthenticationResult")

echo "✅ New ID and Access tokens issued (Refresh Token unchanged)"
echo "   This is how apps silently re-authenticate without prompting the user."
echo ""
echo "============================================================"
echo "  Auth flow complete!"
echo "  Key concepts practised:"
echo "  ✅ Self-registration and admin confirmation"
echo "  ✅ JWT token structure (header.payload.signature)"
echo "  ✅ API Gateway 401 (no token) vs 403 (valid token, insufficient group)"
echo "  ✅ Cognito group claims for RBAC"
echo "  ✅ Token refresh flow"
echo "============================================================"