variable "app_name" {
  type    = string
  default = "myapp"
  description = "Application name - will be suffixed with account ID"
}

variable "cpu" {
  type    = string
  default = "512"
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "task_count" {
  type    = number
  default = 2
}
