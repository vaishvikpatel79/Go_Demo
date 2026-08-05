variable "project_name" {
  description = "Project name used as prefix for resource names"
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID used to construct ECR image URIs."
  type        = string
  default     = "220897588425"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az1" {
  description = "Availability zone for subnet 1"
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "Availability zone for subnet 2"
  type        = string
  default     = "us-east-1b"
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
