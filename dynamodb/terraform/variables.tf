# DynamoDB Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "table_name" {
  description = "Table name"
  type        = string
  default     = ""
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
  default     = "id"
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
  default = [
    {
      name = "id"
      type = "S"
    }
  ]
}

variable "billing_mode" {
  description = "Billing mode: PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  type    = number
  default = 5
}

variable "write_capacity" {
  type    = number
  default = 5
}

variable "ttl_attribute_name" {
  description = "TTL attribute name (empty to disable)"
  type        = string
  default     = ""
}

variable "enable_stream" {
  type    = bool
  default = false
}

variable "stream_view_type" {
  type    = string
  default = "NEW_AND_OLD_IMAGES"
}

variable "global_secondary_indexes" {
  type    = any
  default = []
}

