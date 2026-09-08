variable "project_name" {
  description = "Project name prefix used in resource names."
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (used in resource names and tags)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2."
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_1_az" {
  description = "Availability zone for public subnet 1."
  type        = string
  default     = "us-east-1a"
}

variable "public_subnet_2_az" {
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
  default     = {
    "frontend-service" = "frontend-service"
    "backend-service"  = "backend-service"
  }
}

variable "service_desired_counts" {
  description = "Desired task counts per service."
  type        = map(number)
  default     = {
    "frontend-service" = 1
    "backend-service"  = 1
  }
}

variable "service_cpu" {
  description = "CPU units per service (integer)."
  type        = map(number)
  default     = {
    "frontend-service" = 256
    "backend-service"  = 256
  }
}

variable "service_memory" {
  description = "Memory (MiB) per service."
  type        = map(number)
  default     = {
    "frontend-service" = 512
    "backend-service"  = 512
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 7
}
