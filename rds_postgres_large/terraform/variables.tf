variable "db_name" {
  type    = string
  default = "mydb"
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
  type    = bool
  default = false
}
