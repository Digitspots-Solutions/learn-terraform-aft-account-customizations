# VPC Production Variables

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_name" {
  description = "EKS cluster name for subnet tagging (optional)"
  type        = string
  default     = ""
}

