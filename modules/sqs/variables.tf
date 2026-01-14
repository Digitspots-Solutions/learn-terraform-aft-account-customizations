# SQS Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
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
  default     = true
}

variable "delay_seconds" {
  description = "Delay seconds for messages"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144 # 256 KB
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600 # 4 days
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time"
  type        = number
  default     = 10
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (uses SQS-managed encryption if empty)"
  type        = string
  default     = ""
}

variable "create_dlq" {
  description = "Create a dead letter queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Number of receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

