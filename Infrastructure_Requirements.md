# Project Information

| Field | Value |
|---|---|
| Project Name | go-demo |
| Cloud Provider | AWS |
| Region | us-east-1 |
| Environment | dev |
| Deployment Platform | ECS Fargate |
| Architecture Type | frontend-backend |
| Application Exposure | Public |
| Resource Naming Prefix | go-demo-dev |
| AccountID | 220897588425 |

# 1. Network Layer Requirement

## 1.1 Virtual Private Cloud (VPC)

| Field | Value |
|---|---|
| VPC Name | go-demo-vpc |
| CIDR Block | 10.0.0.0/16 |
| IP Version | IPv4 |
| DNS Resolution Enabled | Yes |
| DNS Hostnames Enabled | Yes |

---

## 1.2 Subnet Configuration

| Subnet Name | Subnet Type | Availability Zone | CIDR Block | Auto Assign Public IP |
|---|---|---|---|---|
| public-subnet-1 | public | us-east-1a | 10.0.1.0/24 | Yes |
| public-subnet-2 | public | us-east-1b | 10.0.2.0/24 | Yes |

---

## 1.3 Internet Connectivity

| Field | Value |
|---|---|
| Internet Gateway Enabled | Yes |
| NAT Gateway Enabled | No |

# 2. Security Layer Requirement

## 2.1 Security Group Configuration

| Security Group Name | Attached Service | Traffic Direction | Protocol | Port | Source / Destination |
|---|---|---|---|---|---|
| alb-sg | Application Load Balancer | Inbound | TCP | 80 | 0.0.0.0/0 |
| alb-sg | Application Load Balancer | Outbound | All | All | frontend-service-sg, backend-service-sg |
| frontend-service-sg | Frontend ECS Service | Inbound | TCP | 80 | alb-sg |
| frontend-service-sg | Frontend ECS Service | Outbound | All | All | Anywhere |
| backend-service-sg | Backend ECS Service | Inbound | TCP | 8080 | alb-sg |
| backend-service-sg | Backend ECS Service | Outbound | All | All | Anywhere |

---

## 2.2 IAM Roles & Permissions

| Role Name | Attached Service | Permissions Required |
|---|---|---|
| ecs-task-execution-role | ECS Task Execution | ECR Pull, CloudWatch Logs |

# 3. Compute Layer Requirement

## 3.1 Compute Platform Configuration

| Field | Value |
|---|---|
| Compute Platform | ECS Fargate |
| Container Registry | Amazon ECR |
| Launch Type | Fargate |
| Operating System | Linux |
| CPU Architecture | x86_64 |

---

## 3.2 Frontend Service Configuration

| Field | Value |
|---|---|
| Service Name | frontend-service |
| Deployment Type | ECS Fargate |
| Desired Task Count | 1 |
| Service Exposure | Public (via Application Load Balancer) |
| Attached Load Balancer | Yes |

---

## 3.3 Frontend Container Runtime Configuration

| Container Port | CPU Units | Memory (MB) | Read Only Root Filesystem | Container Restart Policy |
|---|---|---|---|---|
| 80 | 256 | 512 | No | Always |

---

## 3.4 Frontend Health Check Configuration

| Field | Value |
|---|---|
| Health Check Enabled | Yes |
| Health Check Path | / |
| Health Check Port | traffic-port |
| Health Check Protocol | HTTP |
| Healthy Threshold Count | 2 |
| Unhealthy Threshold Count | 3 |
| Health Check Interval (Seconds) | 30 |

---

## 3.5 Backend Service Configuration

| Field | Value |
|---|---|
| Service Name | backend-service |
| Deployment Type | ECS Fargate |
| Desired Task Count | 1 |
| Service Exposure | Public (via Application Load Balancer) |
| Attached Load Balancer | Yes |

---

## 3.6 Backend Container Runtime Configuration

| Container Port | CPU Units | Memory (MB) | Read Only Root Filesystem | Container Restart Policy |
|---|---|---|---|---|
| 8080 | 256 | 512 | No | Always |

---

## 3.7 Backend Health Check Configuration

| Field | Value |
|---|---|
| Health Check Enabled | Yes |
| Health Check Path | /health |
| Health Check Port | traffic-port |
| Health Check Protocol | HTTP |
| Healthy Threshold Count | 2 |
| Unhealthy Threshold Count | 3 |
| Health Check Interval (Seconds) | 30 |

# 4. Load Balancing & Traffic Layer Requirement

## 4.1 Load Balancer Configuration

| Field | Value |
|---|---|
| Load Balancer Type | Application Load Balancer |
| Exposure Type | Public |
| Scheme | Internet Facing |
| Associated Subnet Type | Public |
| Attached Services | Frontend ECS Service, Backend ECS Service |

---

## 4.2 Listener Configuration

| Listener Name | Protocol | Port | Default Action |
|---|---|---|---|
| http-listener | HTTP | 80 | Forward to Frontend Target Group |

---

## 4.3 Listener Rule Configuration

| Priority | Path Pattern | Target Service |
|---|---|---|
| Default | / | Frontend ECS Service |
| 1 | /api/* | Backend ECS Service |

---

## 4.4 Target Group Configuration

| Target Group Name | Target Service | Protocol | Target Port | Health Check Path |
|---|---|---|---|---|
| go-demo-frontend-tg | Frontend ECS Service | HTTP | 80 | / |
| go-demo-backend-tg | Backend ECS Service | HTTP | 8080 | /health |

# 5. Outputs Required

The infrastructure should return the following Terraform outputs:

| Output | Description |
|---|---|
| Application Load Balancer DNS | Public DNS name of the Application Load Balancer |
| ECS Cluster Name | Name of the ECS Cluster |
| Frontend ECS Service Name | Name of the Frontend ECS Service |
| Backend ECS Service Name | Name of the Backend ECS Service |
| Frontend ECS Task Definition ARN | ARN of the Frontend Task Definition |
| Backend ECS Task Definition ARN | ARN of the Backend Task Definition |
| Frontend ECR Repository URI | Amazon ECR Repository URI for the Frontend image |
| Backend ECR Repository URI | Amazon ECR Repository URI for the Backend image |
| Frontend Target Group ARN | ARN of the Frontend Target Group |
| Backend Target Group ARN | ARN of the Backend Target Group |
| Application URL | Public URL of the deployed application (`http://<ALB-DNS>`) |
