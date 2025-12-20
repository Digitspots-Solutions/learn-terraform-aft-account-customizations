variable "app_name" {
  type    = string
  default = "webapp"
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
