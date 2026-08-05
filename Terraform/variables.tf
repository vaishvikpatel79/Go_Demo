variable "project_name" {
  description = "Project name used in resource naming"
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
  description = "AWS account ID used to construct ECR image URIs. Provided in requirements."
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
  description = "CIDR block for the primary VPC"
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

variable "public_subnet_1_az" {
  description = "Availability zone for public subnet 1"
  type        = string
  default     = "us-east-1a"
}

variable "public_subnet_2_az" {
  description = "Availability zone for public subnet 2"
  type        = string
  default     = "us-east-1b"
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

variable "frontend_cpu" {
  description = "CPU units for frontend container"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for frontend container"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "CPU units for backend container"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (MB) for backend container"
  type        = number
  default     = 512
}

variable "frontend_desired_count" {
  description = "Desired task count for frontend service"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired task count for backend service"
  type        = number
  default     = 1
}

variable "frontend_health_path" {
  description = "Health check path for frontend target group"
  type        = string
  default     = "/"
}

variable "backend_health_path" {
  description = "Health check path for backend target group"
  type        = string
  default     = "/health"
}

variable "frontend_health_interval" {
  description = "Health check interval seconds for frontend target group"
  type        = number
  default     = 30
}

variable "backend_health_interval" {
  description = "Health check interval seconds for backend target group"
  type        = number
  default     = 30
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
