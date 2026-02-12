# SQS Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "queue_name" {
  description = "Queue name (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "fifo" {
  description = "Create a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication (FIFO only)"
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Delay seconds for the queue"
  type        = number
  default     = 0
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 30
}

variable "create_dlq" {
  description = "Create a dead letter queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Max receive count before sending to DLQ"
  type        = number
  default     = 3
}
