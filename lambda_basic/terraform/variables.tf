# Lambda Basic Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "function_name" {
  description = "Lambda function name (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "description" {
  description = "Lambda function description"
  type        = string
  default     = "Managed by Opportunity Portal"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.handler"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}
