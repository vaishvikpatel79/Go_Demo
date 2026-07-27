variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "go-demo"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID used to construct ECR image URIs."
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

variable "dns_resolution_enabled" {
  description = "Enable DNS resolution support for the VPC."
  type        = bool
  default     = true
}

variable "dns_hostnames_enabled" {
  description = "Enable DNS hostnames for the VPC."
  type        = bool
  default     = true
}

variable "managed_by" {
  description = "Tag value for ManagedBy."
  type        = string
  default     = "terraform"
}
