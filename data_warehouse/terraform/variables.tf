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
  default = "ra3.xlplus"  # dc2.large is deprecated, ra3.xlplus is the smallest current option
}

variable "number_of_nodes" {
  type    = number
  default = 2
}
