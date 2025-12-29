variable "app_name" {
  type    = string
  default = "myapp-med"  # Unique name to avoid collision with container_app_small
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
