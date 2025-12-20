variable "app_name" {
  type    = string
  default = "myapp"
}

variable "cpu" {
  type    = string
  default = "2048"
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "task_count" {
  type    = number
  default = 8
}
