variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC."
  type        = bool
  default     = true
}

variable "subnet1_cidr" {
  description = "CIDR block for public subnet 1."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  description = "CIDR block for public subnet 2."
  type        = string
  default     = "10.0.2.0/24"
}

variable "az1" {
  description = "Availability zone for public subnet 1."
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "Availability zone for public subnet 2."
  type        = string
  default     = "us-east-1b"
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
  description = "Desired count for the frontend ECS service."
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired count for the backend ECS service."
  type        = number
  default     = 1
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task (task-level)."
  type        = string
  default     = "256"
}

variable "frontend_memory" {
  description = "Memory (MB) for the frontend task (task-level)."
  type        = string
  default     = "512"
}

variable "backend_cpu" {
  description = "CPU units for the backend task (task-level)."
  type        = string
  default     = "256"
}

variable "backend_memory" {
  description = "Memory (MB) for the backend task (task-level)."
  type        = string
  default     = "512"
}
