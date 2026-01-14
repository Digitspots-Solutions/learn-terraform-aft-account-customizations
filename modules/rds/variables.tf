# RDS Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "identifier" {
  description = "RDS instance identifier (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "engine" {
  description = "Database engine: postgres, mysql, or mariadb"
  type        = string
  default     = "postgres"
  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb."
  }
}

variable "engine_version" {
  description = "Database engine version (if empty, uses latest stable)"
  type        = string
  default     = ""
}

variable "size" {
  description = "Instance size: small, medium, or large"
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "instance_class" {
  description = "Override: specific instance class"
  type        = string
  default     = ""
}

variable "allocated_storage" {
  description = "Override: allocated storage in GB"
  type        = number
  default     = 0
}

variable "max_allocated_storage" {
  description = "Override: maximum storage for autoscaling in GB"
  type        = number
  default     = 0
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master password (if empty, will be auto-generated and stored in Secrets Manager)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR for security group rules"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Database subnet group name"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-06:00"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
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

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

