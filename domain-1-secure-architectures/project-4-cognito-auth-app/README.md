# Project 1.4 – Cognito User Authentication App

**Domain:** Design Secure Architectures  
**Difficulty:** ⭐⭐  
**Estimated Time:** 3–4 hours  
**Approx Cost:** Free Tier eligible (50,000 MAUs free)

---

## 🎯 What You'll Build

A serverless authentication backend using:
- Amazon Cognito User Pool for user sign-up/sign-in
- Cognito Identity Pool for AWS credential vending
- API Gateway with Cognito Authorizer
- Lambda functions protected by Cognito JWT tokens
- Social IdP federation (optional Google login)

---

## 🏗️ Architecture Overview

```
User Browser/App
       │
       ▼
Amazon Cognito User Pool
├── Sign Up / Sign In → returns JWT tokens (ID, Access, Refresh)
├── User Pool Groups: "Admins", "Users"
├── MFA: optional TOTP
└── Social Federation: Google IdP (optional)
       │
       ▼ (JWT Token in Authorization header)
Amazon API Gateway
├── Method: GET /profile  → Cognito Authorizer → Lambda
├── Method: POST /data    → Cognito Authorizer → Lambda
└── Method: GET /admin    → Cognito Authorizer (Admin group) → Lambda
       │
       ▼
AWS Lambda Functions
└── Validate token claims, return user-specific data
```

---

## 📋 What You'll Learn

- Cognito User Pools vs Identity Pools
- JWT tokens: ID token vs Access token vs Refresh token
- API Gateway Cognito Authorizer
- User Pool Groups and group-based authorization
- Difference between authentication (Cognito) and authorization (IAM/policies)

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Create a Cognito User Pool (30 min)
1. **Cognito → Create user pool**
2. Sign-in options: Email
3. Password policy: min 8 chars, require numbers and symbols
4. MFA: Optional (TOTP)
5. Self-registration: Enabled
6. App client: create one called `saa-web-app` (no client secret for browser apps)
7. Note the **User Pool ID** and **App Client ID**

### Phase 2: Create Cognito Identity Pool (30 min)
1. **Cognito → Identity Pools → Create**
2. Link to your User Pool and App Client
3. Authenticated role: create `CognitoAuthRole` with S3 read access
4. Unauthenticated role: minimal permissions only
5. This allows authenticated users to get temporary AWS credentials

### Phase 3: Deploy Lambda + API Gateway (1 hour)
1. Deploy `cloudformation/cognito-api.yaml`
2. This creates:
   - Cognito User Pool + Identity Pool
   - 3 Lambda functions: `GetProfile`, `PostData`, `AdminOnly`
   - API Gateway with Cognito Authorizer
3. Note the API Gateway endpoint URL from the output

### Phase 4: Test Authentication Flow (1 hour)
1. Register a user via CLI:
```bash
aws cognito-idp sign-up \
  --client-id YOUR_APP_CLIENT_ID \
  --username testuser@example.com \
  --password Test@12345

aws cognito-idp admin-confirm-sign-up \
  --user-pool-id YOUR_USER_POOL_ID \
  --username testuser@example.com
```

2. Sign in and get tokens:
```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id YOUR_APP_CLIENT_ID \
  --auth-parameters USERNAME=testuser@example.com,PASSWORD=Test@12345
```

3. Copy the `IdToken` from the response
4. Call the protected API:
```bash
curl -H "Authorization: Bearer YOUR_ID_TOKEN" \
  https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/profile
```

5. Try calling without the token — you should get 401 Unauthorized

### Phase 5: Test Group-Based Authorization (30 min)
1. Add your user to the `Admins` group:
```bash
aws cognito-idp admin-add-user-to-group \
  --user-pool-id YOUR_USER_POOL_ID \
  --username testuser@example.com \
  --group-name Admins
```
2. Sign in again (new token includes group claim)
3. Call the `/admin` endpoint — should now return 200
4. Create a second user NOT in Admins — they should get 403 from the Lambda logic

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/cognito-api.yaml` | Full stack: Cognito, Lambda, API Gateway |
| `lambda/get-profile.py` | Lambda: returns user profile from JWT claims |
| `lambda/admin-only.py` | Lambda: checks Cognito group claim |
| `scripts/auth-flow.sh` | CLI commands for sign-up → sign-in → API call |

---

## 🧹 Cleanup

1. Delete the CloudFormation stack
2. Delete any Cognito User Pools manually if not in CF stack

---

## 📝 Exam Topics Covered

- ✅ Amazon Cognito User Pools (authentication)
- ✅ Amazon Cognito Identity Pools (AWS credential vending)
- ✅ API Gateway with Cognito Authorizer
- ✅ JWT tokens and their contents
- ✅ MFA with Cognito
- ✅ Federated identity (social IdPs)
- ✅ Group-based access control
