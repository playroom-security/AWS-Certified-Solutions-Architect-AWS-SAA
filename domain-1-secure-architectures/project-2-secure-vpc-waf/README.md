# Project 1.2 – Secure VPC with WAF & Shield

**Domain:** Design Secure Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–5 hours  
**Approx Cost:** ~$5–10 (NAT Gateway charges; delete promptly)

---

## 🎯 What You'll Build

A production-grade VPC with layered network security:
- Public and private subnets across 2 Availability Zones
- NAT Gateway for private subnet internet access
- Security Groups as stateful instance-level firewalls
- Network ACLs as stateless subnet-level firewalls
- AWS WAF attached to an Application Load Balancer
- AWS Shield Standard (always on) awareness

---

## 🏗️ Architecture Overview

```
VPC: 10.0.0.0/16
│
├── AZ-1 (us-east-1a)
│   ├── Public Subnet 10.0.1.0/24  → NAT Gateway, ALB nodes
│   └── Private Subnet 10.0.2.0/24 → EC2 Web Servers
│
├── AZ-2 (us-east-1b)
│   ├── Public Subnet 10.0.3.0/24  → ALB nodes
│   └── Private Subnet 10.0.4.0/24 → EC2 Web Servers
│
├── Internet Gateway → attached to VPC
├── Route Tables
│   ├── Public RT: 0.0.0.0/0 → IGW
│   └── Private RT: 0.0.0.0/0 → NAT Gateway
│
├── Security Groups
│   ├── ALB-SG: allow 80/443 from 0.0.0.0/0
│   └── Web-SG: allow 80 from ALB-SG only (no public access)
│
├── Network ACLs
│   ├── Public NACL: allow HTTP/HTTPS in, ephemeral ports out
│   └── Private NACL: allow from public subnet only
│
└── AWS WAF (attached to ALB)
    ├── Rule: Block SQL Injection
    ├── Rule: Block XSS
    ├── Rule: Rate Limiting (100 req/5min per IP)
    └── Rule: AWS Managed Rules – Core Rule Set
```

---

## 📋 What You'll Learn

- VPC design with public/private subnet segmentation
- Difference between Security Groups (stateful) and NACLs (stateless)
- NAT Gateway vs NAT Instance trade-offs
- AWS WAF rules and Web ACLs
- How AWS Shield Standard protects against DDoS automatically
- Defense-in-depth network architecture

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Build the VPC (1 hour)
1. Deploy `cloudformation/vpc-secure.yaml` — this creates the entire VPC, subnets, IGW, NAT Gateway, and route tables
2. Review each resource in the VPC console to understand what was created
3. Check Route Tables: confirm public subnets route to IGW, private to NAT

### Phase 2: Configure Security Groups (30 min)
1. Create **ALB-SG**: Inbound 80, 443 from `0.0.0.0/0`; Outbound all
2. Create **Web-SG**: Inbound 80 from `ALB-SG` only; No direct internet inbound
3. Create **DB-SG**: Inbound 3306 from `Web-SG` only
4. Test: attempt to SSH directly to a private EC2 — it should fail without a bastion

### Phase 3: Configure Network ACLs (30 min)
1. Create a custom NACL for the public subnets
   - Allow inbound: 80, 443 from `0.0.0.0/0`; ephemeral 1024–65535
   - Allow outbound: 80, 443, ephemeral range
2. Create a custom NACL for the private subnets
   - Allow inbound: 80 from `10.0.0.0/16` only
   - Deny all other inbound
3. Notice how NACL rules require explicit allow in both directions (stateless!)

### Phase 4: Deploy a Simple Web App + ALB (1 hour)
1. Launch 2 EC2 instances (t2.micro, Amazon Linux 2) in private subnets
2. Use User Data to install Apache: `yum install -y httpd && systemctl start httpd`
3. Create an Application Load Balancer in public subnets with ALB-SG
4. Create a Target Group pointing to the EC2 instances
5. Test: access the ALB DNS name in a browser

### Phase 5: Attach AWS WAF (1 hour)
1. Go to **AWS WAF → Web ACLs → Create**
2. Associate with your ALB
3. Add AWS Managed Rules: `AWSManagedRulesCommonRuleSet`
4. Add custom rule: Rate-based rule (100 requests per 5 minutes per IP)
5. Add custom rule: SQL injection match — block requests with `' OR 1=1` in query string
6. Test WAF by sending a crafted request: `curl "http://ALB_DNS/?id=1' OR '1'='1"` — should get 403

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/vpc-secure.yaml` | Full VPC with subnets, IGW, NAT, route tables |
| `cloudformation/ec2-web-servers.yaml` | EC2 instances in private subnets + ALB |
| `cloudformation/waf-web-acl.yaml` | WAF Web ACL with managed rules |
| `scripts/test-waf.sh` | Shell script to test WAF rules |

---

## 🧹 Cleanup

**Important:** NAT Gateways cost ~$0.045/hr. Delete after testing!

1. Delete WAF Web ACL
2. Delete ALB and Target Group
3. Terminate EC2 instances
4. Delete the CloudFormation stacks (this removes VPC, NAT GW, subnets)

---

## 📝 Exam Topics Covered

- ✅ VPC design with public and private subnets
- ✅ Security Groups vs Network ACLs (stateful vs stateless)
- ✅ NAT Gateway for private subnet internet access
- ✅ AWS WAF rules and Web ACLs
- ✅ AWS Shield Standard
- ✅ Defense-in-depth network architecture
- ✅ ALB as an entry point with WAF protection
