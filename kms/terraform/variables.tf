# KMS Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "key_alias" {
  description = "Key alias (without prefix)"
  type        = string
  default     = "app-key"
}

variable "description" {
  type    = string
  default = "Customer managed encryption key - Deployed by Opportunity Portal"
}

variable "deletion_window_in_days" {
  type    = number
  default = 7
}

