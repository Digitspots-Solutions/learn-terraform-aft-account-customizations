variable "db_name" {
  type    = string
  default = "mydb-sm"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "storage_gb" {
  type    = number
  default = 20
}

variable "master_username" {
  type    = string
  default = "postgres"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}
