# EFS Stack Variables

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "performance_mode" {
  type        = string
  default     = "generalPurpose"
  description = "EFS performance mode: generalPurpose or maxIO"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be generalPurpose or maxIO"
  }
}

variable "throughput_mode" {
  type        = string
  default     = "bursting"
  description = "EFS throughput mode: bursting, provisioned, or elastic"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be bursting, provisioned, or elastic"
  }
}

variable "provisioned_throughput" {
  type        = number
  default     = 100
  description = "Provisioned throughput in MiB/s (only when throughput_mode is provisioned)"
}

variable "transition_to_ia" {
  type        = string
  default     = "AFTER_30_DAYS"
  description = "Lifecycle policy for transitioning to IA storage class"
}

variable "enable_backups" {
  type        = bool
  default     = true
  description = "Enable automatic backups"
}

variable "create_access_point" {
  type        = bool
  default     = true
  description = "Create an access point for container integration"
}

