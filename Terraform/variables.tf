variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID used to construct ECR image URIs."
  type        = string
  default     = "220897588425"
}

variable "service_tags" {
  description = "Map of service name to image tag. Terraform constructs full ECR URIs from this map."
  type        = map(string)
  default     = {}
}

variable "service_repositories" {
  description = "Map of logical service name to container repository name."
  type        = map(string)
  default = {
    "go-demo-frontend-service" = "go-demo-frontend-service"
    "go-demo-backend-service"  = "go-demo-backend-service"
  }
}

variable "frontend_desired_count" {
  description = "Desired task count for the frontend ECS service"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired task count for the backend ECS service"
  type        = number
  default     = 1
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for the frontend task"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "CPU units for the backend task"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (MB) for the backend task"
  type        = number
  default     = 512
}
