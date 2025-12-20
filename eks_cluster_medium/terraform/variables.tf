variable "cluster_name" {
  type    = string
  default = "mycluster"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "node_count" {
  type    = number
  default = 4
}
