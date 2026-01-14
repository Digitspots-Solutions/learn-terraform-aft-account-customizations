# Lambda API Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "function_name" {
  type    = string
  default = ""
}

variable "description" {
  type    = string
  default = "API Lambda - Deployed by Opportunity Portal"
}

variable "language" {
  type    = string
  default = "python"
}

variable "handler" {
  type    = string
  default = "handler.handler"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout" {
  type    = number
  default = 30
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "cors_origins" {
  type    = list(string)
  default = ["*"]
}

