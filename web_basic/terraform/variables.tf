variable "app_name" {
  type        = string
  default     = "basic"
  description = "Application name prefix"
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum instances in ASG"
}

variable "max_size" {
  type        = number
  default     = 3
  description = "Maximum instances in ASG"
}

variable "desired_size" {
  type        = number
  default     = 1
  description = "Desired instances in ASG"
}

