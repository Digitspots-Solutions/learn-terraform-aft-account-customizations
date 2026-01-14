# RDS PostgreSQL Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_stack" {
  description = "VPC stack name for remote state lookup"
  type        = string
  default     = "vpc_basic"
}

variable "identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = ""
}

variable "engine_version" {
  description = "PostgreSQL version (empty for latest)"
  type        = string
  default     = ""
}

variable "size" {
  description = "Instance size: small, medium, or large"
  type        = string
  default     = "small"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = true
}

