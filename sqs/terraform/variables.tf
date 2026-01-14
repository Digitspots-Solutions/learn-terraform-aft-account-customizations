# SQS Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "queue_name" {
  type    = string
  default = ""
}

variable "fifo" {
  type    = bool
  default = false
}

variable "content_based_deduplication" {
  type    = bool
  default = true
}

variable "delay_seconds" {
  type    = number
  default = 0
}

variable "message_retention_seconds" {
  type    = number
  default = 345600  # 4 days
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "create_dlq" {
  type    = bool
  default = true
}

variable "max_receive_count" {
  type    = number
  default = 3
}

