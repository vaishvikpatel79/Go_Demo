variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID used to construct ECR image URIs. Required input."
  type        = string
}

variable "service_tags" {
  description = "Map of service name to image tag. Terraform constructs full ECR URIs from this map."
  type        = map(string)
  default     = {}
}

variable "service_repositories" {
  description = "Map of logical service name to container repository name."
  type        = map(string)
  default     = {}
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

variable "frontend_cpu_units" {
  description = "CPU units for the frontend container (task)"
  type        = number
  default     = 256
}

variable "backend_cpu_units" {
  description = "CPU units for the backend container (task)"
  type        = number
  default     = 256
}

variable "frontend_memory_mb" {
  description = "Memory (MB) for the frontend container (task)"
  type        = number
  default     = 512
}

variable "backend_memory_mb" {
  description = "Memory (MB) for the backend container (task)"
  type        = number
  default     = 512
}

variable "frontend_container_port" {
  description = "Container port for the frontend service"
  type        = number
  default     = 80
}

variable "backend_container_port" {
  description = "Container port for the backend service"
  type        = number
  default     = 8080
}
