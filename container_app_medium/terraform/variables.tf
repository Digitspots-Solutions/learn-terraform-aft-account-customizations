variable "app_name" {
  type    = string
  default = "myapp-${data.aws_caller_identity.current.account_id}"
}

variable "cpu" {
  type    = string
  default = "1024"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "task_count" {
  type    = number
  default = 4
}
