variable "cluster_name" {
  type    = string
  default = "datawarehouse"
}

variable "database_name" {
  type    = string
  default = "analytics"
}

variable "master_username" {
  type    = string
  default = "admin"
}

variable "node_type" {
  type    = string
  default = "dc2.large"
}

variable "number_of_nodes" {
  type    = number
  default = 2
}
