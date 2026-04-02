# Project 1.1 – IAM Multi-Account Security Setup

**Domain:** Design Secure Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–6 hours  
**Approx Cost:** Free Tier eligible

---

## 🎯 What You'll Build

A multi-account AWS environment using AWS Organizations with:
- A Management account and two child accounts (Dev & Prod)
- Service Control Policies (SCPs) that restrict what child accounts can do
- IAM roles with cross-account access
- MFA enforcement for all IAM users
- IAM Identity Center (SSO) for centralized login

---

## 🏗️ Architecture Overview

```
Management Account (Root)
├── AWS Organizations
│   ├── SCP: DenyRootLogin, RequireMFA, RestrictRegions
│   ├── OU: Development
│   │   └── Dev Account → IAM Role: DevRole (limited S3, EC2)
│   └── OU: Production
│       └── Prod Account → IAM Role: ProdReadOnly
└── IAM Identity Center (SSO)
    └── Permission Sets → mapped to accounts
```

---

## 📋 What You'll Learn

- Principle of least privilege with IAM policies
- Cross-account role switching with AWS STS
- SCP design and inheritance across OUs
- Difference between IAM policies and SCPs
- Federated access with IAM Identity Center

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Set Up AWS Organizations (1 hour)
1. Log in to your Management account
2. Go to **AWS Organizations → Create organization**
3. Enable all features (not just consolidated billing)
4. Create two OUs: `Development` and `Production`
5. Create or invite two member accounts into each OU

### Phase 2: Apply Service Control Policies (1 hour)
1. In AWS Organizations → Policies → SCPs, enable SCPs
2. Deploy `scp-deny-root.json` — attaches to root OU
3. Deploy `scp-require-mfa.json` — attaches to all OUs
4. Deploy `scp-restrict-regions.json` — limits to us-east-1 and us-west-2
5. Test: try to launch EC2 in eu-west-1 from a member account (should fail)

### Phase 3: Create Cross-Account IAM Roles (1 hour)
1. In Dev account, create role `DevCrossAccountRole`
   - Trust policy: allow Management account to assume it
   - Permissions: AmazonEC2ReadOnlyAccess, AmazonS3ReadOnlyAccess
2. In Management account, create IAM user `developer-user`
3. Grant that user permission to call `sts:AssumeRole` on DevCrossAccountRole
4. Test role switching in the console and with AWS CLI

### Phase 4: Enable IAM Identity Center SSO (1 hour)
1. In Management account → IAM Identity Center → Enable
2. Create a user in the Identity Center directory
3. Create two Permission Sets: `DevAccess` and `ReadOnlyAccess`
4. Assign users to accounts with appropriate Permission Sets
5. Log in via the SSO portal URL and test access

### Phase 5: Enforce MFA & Review (30 min)
1. Apply `iam-policy-require-mfa.json` to IAM groups
2. Enable MFA on your root account
3. Use IAM Credential Report to audit user MFA status
4. Review with AWS Trusted Advisor → Security checks

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/organizations-setup.yaml` | Bootstraps OU structure |
| `policies/scp-deny-root.json` | SCP: blocks root user actions |
| `policies/scp-require-mfa.json` | SCP: denies actions without MFA |
| `policies/scp-restrict-regions.json` | SCP: limits allowed regions |
| `policies/iam-cross-account-role.json` | Trust + permission policy for cross-account role |
| `policies/iam-policy-require-mfa.json` | IAM policy enforcing MFA for users |

---

## 🧹 Cleanup

1. Detach and delete all SCPs
2. Remove member accounts from OUs
3. Delete IAM users and roles in all accounts
4. Disable IAM Identity Center

---

## 📝 Exam Topics Covered

- ✅ IAM users, groups, roles, and policies
- ✅ AWS Organizations and SCPs
- ✅ Cross-account access with STS AssumeRole
- ✅ MFA enforcement
- ✅ AWS Control Tower concepts
- ✅ Principle of least privilege
- ✅ Federated access with IAM Identity Center
