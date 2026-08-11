variable "project_name" {
  description = "Project name prefix used in resource names and tags"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
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

variable "frontend_desired_count" {
  description = "Desired task count for the frontend-service ECS service"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired task count for the backend-service ECS service"
  type        = number
  default     = 1
}

variable "frontend_container_port" {
  description = "Container port for the frontend-service"
  type        = number
  default     = 80
}

variable "backend_container_port" {
  description = "Container port for the backend-service"
  type        = number
  default     = 8080
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task definition (string as required by ECS task definition)"
  type        = string
  default     = "256"
}

variable "frontend_memory" {
  description = "Memory (MiB) for the frontend task definition (string as required by ECS task definition)"
  type        = string
  default     = "512"
}

variable "backend_cpu" {
  description = "CPU units for the backend task definition (string as required by ECS task definition)"
  type        = string
  default     = "256"
}

variable "backend_memory" {
  description = "Memory (MiB) for the backend task definition (string as required by ECS task definition)"
  type        = string
  default     = "512"
}

variable "frontend_health_path" {
  description = "Health check path for frontend target group"
  type        = string
  default     = "/"
}

variable "frontend_healthy_threshold" {
  description = "Healthy threshold count for frontend target group"
  type        = number
  default     = 2
}

variable "frontend_unhealthy_threshold" {
  description = "Unhealthy threshold count for frontend target group"
  type        = number
  default     = 3
}

variable "frontend_health_check_interval" {
  description = "Health check interval seconds for frontend target group"
  type        = number
  default     = 30
}

variable "backend_health_path" {
  description = "Health check path for backend target group"
  type        = string
  default     = "/health"
}

variable "backend_healthy_threshold" {
  description = "Healthy threshold count for backend target group"
  type        = number
  default     = 2
}

variable "backend_unhealthy_threshold" {
  description = "Unhealthy threshold count for backend target group"
  type        = number
  default     = 3
}

variable "backend_health_check_interval" {
  description = "Health check interval seconds for backend target group"
  type        = number
  default     = 30
}
