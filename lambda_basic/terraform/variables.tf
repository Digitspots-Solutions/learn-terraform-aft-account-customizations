# Lambda Basic Variables

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = ""
}

variable "description" {
  description = "Lambda function description"
  type        = string
  default     = "Deployed by Opportunity Portal"
}

variable "language" {
  description = "Programming language: python, nodejs, go"
  type        = string
  default     = "python"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.handler"
}

variable "architecture" {
  description = "Lambda architecture: x86_64 or arm64"
  type        = string
  default     = "arm64"
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

