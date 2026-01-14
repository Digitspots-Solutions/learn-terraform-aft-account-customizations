# ECS Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for service discovery"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable Container Insights for monitoring"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Enable Cloud Map service discovery"
  type        = bool
  default     = true
}

variable "fargate_spot_weight" {
  description = "Weight for Fargate Spot capacity (0-100)"
  type        = number
  default     = 0
  validation {
    condition     = var.fargate_spot_weight >= 0 && var.fargate_spot_weight <= 100
    error_message = "Fargate Spot weight must be between 0 and 100."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

