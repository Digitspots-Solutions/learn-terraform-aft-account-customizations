# SNS Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "topic_name" {
  type    = string
  default = ""
}

variable "fifo" {
  type    = bool
  default = false
}

