variable "project_name" {
  description = "Project name used in resource names"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into"
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
  default     = {
    "frontend-service" = "frontend-service"
    "backend-service"  = "backend-service"
  }
}

variable "desired_task_count_frontend" {
  description = "Desired task count for the frontend service"
  type        = number
  default     = 1
}

variable "desired_task_count_backend" {
  description = "Desired task count for the backend service"
  type        = number
  default     = 1
}

variable "cpu_frontend" {
  description = "CPU units for frontend task"
  type        = number
  default     = 256
}

variable "memory_frontend" {
  description = "Memory (MB) for frontend task"
  type        = number
  default     = 512
}

variable "cpu_backend" {
  description = "CPU units for backend task"
  type        = number
  default     = 256
}

variable "memory_backend" {
  description = "Memory (MB) for backend task"
  type        = number
  default     = 512
}
