# EKS Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name (if empty, will be auto-generated from name_prefix)"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "environment" {
  description = "Environment type: starter, development, or production"
  type        = string
  default     = "development"
  validation {
    condition     = contains(["starter", "development", "production"], var.environment)
    error_message = "Environment must be one of: starter, development, production."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

