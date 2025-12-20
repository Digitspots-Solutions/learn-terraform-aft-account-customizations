variable "cluster_name" {
  type    = string
  default = "mycluster"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_count" {
  type    = number
  default = 2
}
