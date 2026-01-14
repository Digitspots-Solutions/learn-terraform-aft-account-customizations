# Lambda Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
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

variable "language" {
  description = "Programming language: python, nodejs, go, java, dotnet"
  type        = string
  default     = "python"
  validation {
    condition     = contains(["python", "nodejs", "go", "java", "dotnet"], var.language)
    error_message = "Language must be one of: python, nodejs, go, java, dotnet."
  }
}

variable "runtime" {
  description = "Override: specific runtime version"
  type        = string
  default     = ""
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
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be x86_64 or arm64."
  }
}

variable "source_path" {
  description = "Path to source code for packaging"
  type        = string
  default     = ""
}

variable "hash_extra" {
  description = "Extra string to add to hash for cache busting"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 bucket containing deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "Container image URI for container Lambda"
  type        = string
  default     = null
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

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (-1 for no limit)"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for Lambda (empty for no VPC)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for Lambda"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "dead_letter_queue_arn" {
  description = "ARN of SQS queue or SNS topic for dead letters"
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "policy_json" {
  description = "Custom IAM policy JSON"
  type        = string
  default     = ""
}

variable "policy_statements" {
  description = "Map of IAM policy statements"
  type        = any
  default     = {}
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "event_source_mapping" {
  description = "Map of event source mapping configurations"
  type        = any
  default     = {}
}

variable "allowed_triggers" {
  description = "Map of allowed triggers for Lambda"
  type        = map(any)
  default     = {}
}

variable "create_api_gateway" {
  description = "Create API Gateway HTTP API for the Lambda"
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "Allowed CORS origins for API Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

