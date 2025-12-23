variable "app_name" {
  type    = string
  default = "webapp-${data.aws_caller_identity.current.account_id}"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "min_size" {
  type    = number
  default = 4
}

variable "max_size" {
  type    = number
  default = 10
}

variable "desired_size" {
  type    = number
  default = 4
}
