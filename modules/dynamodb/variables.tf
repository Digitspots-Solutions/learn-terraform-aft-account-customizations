# DynamoDB Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "table_name" {
  description = "Table name (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
}

variable "range_key" {
  description = "Sort key attribute name (optional)"
  type        = string
  default     = ""
}

variable "attributes" {
  description = "List of attribute definitions"
  type = list(object({
    name = string
    type = string
  }))
}

variable "billing_mode" {
  description = "Billing mode: PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Read capacity units (for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "table_class" {
  description = "Table class: STANDARD or STANDARD_INFREQUENT_ACCESS"
  type        = string
  default     = "STANDARD"
}

variable "global_secondary_indexes" {
  description = "List of GSI configurations"
  type        = any
  default     = []
}

variable "local_secondary_indexes" {
  description = "List of LSI configurations"
  type        = any
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (uses AWS managed key if empty)"
  type        = string
  default     = null
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "ttl_attribute_name" {
  description = "TTL attribute name (empty to disable TTL)"
  type        = string
  default     = ""
}

variable "enable_stream" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "enable_autoscaling" {
  description = "Enable autoscaling (for PROVISIONED mode)"
  type        = bool
  default     = true
}

variable "replica_regions" {
  description = "List of regions for global tables"
  type = list(object({
    region_name = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

