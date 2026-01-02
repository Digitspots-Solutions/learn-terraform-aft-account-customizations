variable "db_name" {
  type    = string
  default = "mydb-lg"
}

variable "instance_class" {
  type    = string
  default = "db.r5.large"
}

variable "storage_gb" {
  type    = number
  default = 500
}

variable "master_username" {
  type    = string
  default = "postgres"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type        = bool
  default     = true  # Set to true to allow clean destruction via portal
  description = "Skip final snapshot on destroy. Set to false and provide final_snapshot_identifier for production."
}
