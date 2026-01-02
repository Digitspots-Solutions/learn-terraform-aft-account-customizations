variable "app_name" {
  type        = string
  default     = "enterprise"
  description = "Application name prefix"
}

variable "instance_type" {
  type        = string
  default     = "c6i.xlarge"
  description = "Compute-optimized instance type"
}

variable "min_size" {
  type        = number
  default     = 4
  description = "Minimum instances in ASG"
}

variable "max_size" {
  type        = number
  default     = 16
  description = "Maximum instances in ASG"
}

variable "desired_size" {
  type        = number
  default     = 4
  description = "Desired instances in ASG"
}


