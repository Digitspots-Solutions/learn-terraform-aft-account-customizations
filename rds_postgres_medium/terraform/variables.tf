variable "db_name" {
  type    = string
  default = "mydb-${data.aws_caller_identity.current.account_id}"
}

variable "instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "storage_gb" {
  type    = number
  default = 100
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
  type    = bool
  default = true
}
