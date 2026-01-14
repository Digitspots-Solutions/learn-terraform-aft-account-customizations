# MSK Stack Variables

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "kafka_version" {
  type        = string
  default     = "3.5.1"
  description = "Apache Kafka version"
}

variable "broker_count" {
  type        = number
  default     = 3
  description = "Number of broker nodes (must be multiple of AZs)"
}

variable "instance_type" {
  type        = string
  default     = "kafka.m5.large"
  description = "EC2 instance type for brokers"
}

variable "ebs_volume_size" {
  type        = number
  default     = 100
  description = "EBS volume size per broker in GB"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days"
}

