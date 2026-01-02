variable "app_name" {
  type        = string
  default     = "starter"
  description = "Application name prefix"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type (t3.micro for lowest cost)"
}


