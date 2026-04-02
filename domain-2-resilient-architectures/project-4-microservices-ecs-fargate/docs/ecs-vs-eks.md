# ECS vs EKS – Decision Guide
## SAA Study Project 2.4 – Key Exam Reference

---

## Quick Decision Matrix

| Factor | ECS (Fargate) | ECS (EC2) | EKS |
|---|---|---|---|
| **Kubernetes** | No | No | Yes |
| **Managed control plane** | Yes | Yes | Yes (paid) |
| **Manage worker nodes** | No ✅ | Yes | Yes (unless Fargate) |
| **Cost** | Pay per task | Pay per EC2 | Control plane + nodes |
| **Learning curve** | Low | Low | High |
| **Ecosystem / portability** | AWS-only | AWS-only | K8s standard ✅ |
| **Best for** | Simpler apps, AWS-native | Cost-sensitive, GPU | Complex, multi-cloud |

---

## When to Use ECS (Fargate) ← This Project
- Team is new to containers and doesn't need Kubernetes
- You want AWS to manage ALL infrastructure (no EC2, no nodes)
- Simpler microservices that fit well into AWS-native tooling
- Cost: pay only for the CPU/memory your tasks consume

## When to Use ECS (EC2 Launch Type)
- Need GPU instances (Fargate doesn't support GPU)
- Need to customise the underlying host
- Higher container density is needed to reduce cost
- Spot Instance support for batch workloads

## When to Use EKS
- Organisation already uses Kubernetes and wants portability
- Complex multi-cloud or hybrid deployments
- Need advanced K8s features: custom controllers, operators, CRDs
- Large engineering teams with Kubernetes expertise
- EKS Anywhere: run the same Kubernetes on-premises

---

## Key ECS Concepts for the Exam

### Cluster
The logical grouping of tasks and services. Think of it as your "deployment environment".

### Task Definition
A blueprint (like a Docker Compose file) that defines:
- Container image(s) to run
- CPU and memory
- Port mappings
- Environment variables
- IAM role (task role)
- Logging configuration

### Task
A running instance of a Task Definition. Equivalent to a pod in Kubernetes.

### Service
Maintains a desired number of running tasks. Handles:
- Desired count (e.g., 2 tasks always running)
- Integration with ALB
- Rolling deployments
- Auto scaling

---

## IAM Roles in ECS (Common Exam Confusion!)

| Role | Purpose |
|---|---|
| **Task Execution Role** | Allows ECS *agent* to pull images from ECR and push logs to CloudWatch |
| **Task Role** | Permissions your *application code* needs (e.g., read from S3, write to DynamoDB) |

They are different roles! Task Role = what your app can do. Execution Role = what ECS can do.

---

## ECS Service Deployment Strategies

| Strategy | Description | Downtime |
|---|---|---|
| **Rolling Update** | Replace tasks gradually (default) | Minimal |
| **Blue/Green (CodeDeploy)** | Run new version alongside old, then switch | None |
| **External** | Use your own deployment controller | Varies |

---

## Exam Tips

- "Serverless containers" → **ECS Fargate** (no EC2 management)
- "Run containers without managing infrastructure" → **ECS Fargate**
- "Kubernetes" explicitly mentioned → **EKS**
- "Migrate existing K8s workload to AWS" → **EKS**
- "Run containers on-premises with AWS management" → **ECS Anywhere** or **EKS Anywhere**
- ECR = private container registry for storing Docker images
