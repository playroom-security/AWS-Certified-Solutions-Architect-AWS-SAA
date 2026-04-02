# Project 2.4 – Microservices with Amazon ECS Fargate

**Domain:** Design Resilient Architectures  
**Difficulty:** ⭐⭐⭐⭐  
**Estimated Time:** 5–6 hours  
**Approx Cost:** ~$5–10 (Fargate pricing; delete after)

---

## 🎯 What You'll Build

A containerised microservices application running on ECS Fargate:
- 3 microservices: Users, Products, Orders
- Each service runs as an ECS Fargate task (no EC2 to manage)
- Application Load Balancer with path-based routing to each service
- Amazon ECR for container image storage
- Service auto scaling based on CPU utilisation
- Service discovery via AWS Cloud Map

---

## 🏗️ Architecture Overview

```
ALB: api.saa-study.com
├── /users/*   → Target Group → ECS Service: UserService   (Fargate)
├── /products/*→ Target Group → ECS Service: ProductService (Fargate)
└── /orders/*  → Target Group → ECS Service: OrderService  (Fargate)

Amazon ECR
├── saa-users-service:latest
├── saa-products-service:latest
└── saa-orders-service:latest

ECS Cluster: saa-microservices
└── All services run as Fargate tasks (serverless compute)
    ├── Task CPU: 256 (.25 vCPU), Memory: 512 MB
    ├── Service desired count: 2 (across 2 AZs)
    └── Auto Scaling: CPU > 70% → scale out

Service Discovery (Cloud Map)
└── orders.saa-local → resolves to OrderService IPs internally
```

---

## 📋 What You'll Learn

- ECS concepts: Cluster, Service, Task Definition, Task
- ECS Fargate vs EC2 launch type trade-offs
- ECR: pushing and pulling container images
- ALB path-based routing to multiple target groups
- ECS service auto scaling
- Difference between ECS, EKS, and when to use each

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Build and Push Container Images to ECR (1 hour)
1. Create 3 ECR repositories:
```bash
for svc in users products orders; do
  aws ecr create-repository --repository-name saa-$svc-service --region us-east-1
done
```
2. Authenticate Docker to ECR:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```
3. Build and push each service from the `services/` directory:
```bash
cd services/users-service
docker build -t saa-users-service .
docker tag saa-users-service:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/saa-users-service:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/saa-users-service:latest
```

### Phase 2: Create the ECS Cluster (15 min)
1. ECS → Create Cluster → Fargate (serverless) — no EC2 to manage
2. Name: `saa-microservices`
3. Enable Container Insights (CloudWatch monitoring)

### Phase 3: Create Task Definitions (45 min)
1. Deploy `cloudformation/task-definitions.yaml`
2. Creates 3 task definitions, one per service
3. Review a task definition:
   - Launch type: FARGATE
   - CPU: 256, Memory: 512
   - Container: image URI from ECR, port 3000, environment variables
   - Task role: IAM role allowing the container to access DynamoDB
   - Execution role: allows ECS to pull from ECR and write logs to CloudWatch

### Phase 4: Deploy ECS Services + ALB (1 hour)
1. Deploy `cloudformation/ecs-services.yaml`
2. Creates ALB with 3 target groups (path-based routing rules)
3. Creates 3 ECS services, each with desired count = 2
4. Wait for services to reach steady state (~5 minutes)
5. Test path-based routing:
```bash
ALB_DNS="your-alb-dns.us-east-1.elb.amazonaws.com"
curl http://$ALB_DNS/users/health      # → UserService
curl http://$ALB_DNS/products/health   # → ProductService
curl http://$ALB_DNS/orders/health     # → OrderService
```

### Phase 5: Configure Auto Scaling (30 min)
1. In ECS → Cluster → UserService → Auto Scaling → Create
2. Min: 2, Max: 10
3. Target tracking: ECSServiceAverageCPUUtilization at 70%
4. Test by generating load to the /users endpoint
5. Watch new Fargate tasks launch automatically (no EC2 management!)

### Phase 6: Explore ECS vs EKS Decision Framework (30 min)
Review `docs/ecs-vs-eks.md` for when to choose each orchestrator.

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `services/users-service/` | Node.js Users microservice + Dockerfile |
| `services/products-service/` | Node.js Products microservice + Dockerfile |
| `services/orders-service/` | Node.js Orders microservice + Dockerfile |
| `cloudformation/task-definitions.yaml` | ECS Task Definitions for all 3 services |
| `cloudformation/ecs-services.yaml` | ECS Services, ALB, target groups |
| `scripts/build-push-all.sh` | Builds and pushes all 3 images to ECR |
| `docs/ecs-vs-eks.md` | Decision guide: ECS vs EKS |

---

## 🧹 Cleanup

1. Scale ECS services to 0 first (faster cleanup)
2. Delete CloudFormation stacks
3. Delete ECR repositories (and images)
4. Delete ECS cluster

---

## 📝 Exam Topics Covered

- ✅ Amazon ECS: Cluster, Service, Task Definition, Task
- ✅ Fargate vs EC2 launch type
- ✅ Amazon ECR for container image registry
- ✅ ALB path-based routing
- ✅ ECS Service Auto Scaling
- ✅ ECS vs EKS decision criteria
- ✅ Container-based microservices architecture
