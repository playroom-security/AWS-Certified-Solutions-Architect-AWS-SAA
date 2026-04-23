# AWS Certified Solutions Architect – Associate (SAA-C03)
![aws-saa](./assets/aws-saa-logo.png)
## Hands-On Study Projects

> **Goal:** Complete these 16 projects over ~4 weeks to reinforce every exam domain through real AWS experience.

---

## 📅 Suggested 4-Week Timeline

| Week | Focus Domain | Projects |
|------|-------------|----------|
| Week 1 | Domain 1 – Secure Architectures (30%) | Projects 1.1 → 1.4 |
| Week 2 | Domain 2 – Resilient Architectures (26%) | Projects 2.1 → 2.4 |
| Week 3 | Domain 3 – High-Performing Architectures (24%) | Projects 3.1 → 3.4 |
| Week 4 | Domain 4 – Cost-Optimized Architectures (20%) | Projects 4.1 → 4.4 |

---

## 🗂️ Project Overview

### Domain 1 – Design Secure Architectures
| # | Project | Key Services |
|---|---------|-------------|
| 1.1 | IAM Multi-Account Security Setup | IAM, AWS Organizations, SCPs, Control Tower |
| 1.2 | Secure VPC with WAF & Shield | VPC, WAF, Shield, Security Groups, NACLs |
| 1.3 | KMS Encryption + Secrets Manager | KMS, Secrets Manager, S3, RDS |
| 1.4 | Cognito User Auth App | Cognito, API Gateway, Lambda |

### Domain 2 – Design Resilient Architectures
| # | Project | Key Services |
|---|---------|-------------|
| 2.1 | Multi-AZ Web App with Auto Scaling | EC2, ALB, Auto Scaling, RDS Multi-AZ |
| 2.2 | Serverless Event-Driven Pipeline | Lambda, SQS, SNS, EventBridge |
| 2.3 | Disaster Recovery – Pilot Light | Route 53, RDS, EC2, CloudFormation |
| 2.4 | Microservices with ECS Fargate | ECS, Fargate, ECR, ALB |

### Domain 3 – Design High-Performing Architectures
| # | Project | Key Services |
|---|---------|-------------|
| 3.1 | CloudFront + S3 Static Website CDN | S3, CloudFront, ACM, Route 53 |
| 3.2 | ElastiCache Caching Layer | ElastiCache (Redis), RDS, EC2 |
| 3.3 | Kinesis Real-Time Streaming Pipeline | Kinesis, Lambda, S3, Athena |
| 3.4 | Aurora with Read Replicas | Aurora, RDS Proxy, ElastiCache |

### Domain 4 – Design Cost-Optimized Architectures
| # | Project | Key Services |
|---|---------|-------------|
| 4.1 | Spot + Reserved Instance Strategy | EC2 Spot, Auto Scaling, Savings Plans |
| 4.2 | S3 Lifecycle Policies + Glacier | S3, S3 Glacier, S3 Intelligent-Tiering |
| 4.3 | Cost Monitoring Dashboard | Cost Explorer, Budgets, CloudWatch |
| 4.4 | Serverless vs EC2 Cost Comparison | Lambda, EC2, Cost and Usage Report |

---

## 💡 Tips Before You Start

- **Use a Free Tier account** or AWS Organizations sandbox where possible.
- **Always clean up resources** after each project to avoid unexpected charges.
- Each project folder contains a `README.md` with architecture diagram, step-by-step instructions, and exam topic mapping.
- Use `CloudFormation` templates provided in each project to deploy and tear down cleanly.
- Tag every resource with `Project: SAA-Study` and `Domain: DomainNumber` for easy cost tracking.

---

## 🔗 Useful Links
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS SAA Exam Guide](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
