variable "project_name" {
  description = "Project name used in resource naming"
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

variable "account_id" {
  description = "AWS account ID used to construct ECR image URIs."
  type        = string
  default     = "220897588425"
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
  default     = 1
}

variable "frontend_container_port" {
  description = "Container port for frontend service"
  type        = number
  default     = 80
}

variable "backend_container_port" {
  description = "Container port for backend service"
  type        = number
  default     = 8080
}

variable "frontend_cpu_units" {
  description = "CPU units for frontend container/task"
  type        = number
  default     = 256
}

variable "frontend_memory_mb" {
  description = "Memory (MB) for frontend container/task"
  type        = number
  default     = 512
}

variable "backend_cpu_units" {
  description = "CPU units for backend container/task"
  type        = number
  default     = 256
}

variable "backend_memory_mb" {
  description = "Memory (MB) for backend container/task"
  type        = number
  default     = 512
}
