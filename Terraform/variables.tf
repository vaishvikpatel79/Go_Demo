variable "project_name" {
  description = "Project name used in resource names"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment"
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
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az1" {
  description = "Availability zone for public subnet 1"
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "Availability zone for public subnet 2"
  type        = string
  default     = "us-east-1b"
}

variable "desired_count_frontend" {
  description = "Desired task count for the frontend service"
  type        = number
  default     = 1
}

variable "desired_count_backend" {
  description = "Desired task count for the backend service"
  type        = number
  default     = 1
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

variable "frontend_cpu" {
  description = "CPU units for the frontend task definition"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for the frontend task definition"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "CPU units for the backend task definition"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (MB) for the backend task definition"
  type        = number
  default     = 512
}
