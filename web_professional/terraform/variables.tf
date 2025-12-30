variable "app_name" {
  type        = string
  default     = "pro"
  description = "Application name prefix"
}

variable "instance_type" {
  type        = string
  default     = "t3.large"
  description = "EC2 instance type"
}

variable "min_size" {
  type        = number
  default     = 2
  description = "Minimum instances in ASG"
}

variable "max_size" {
  type        = number
  default     = 8
  description = "Maximum instances in ASG"
}

variable "desired_size" {
  type        = number
  default     = 2
  description = "Desired instances in ASG"
}

