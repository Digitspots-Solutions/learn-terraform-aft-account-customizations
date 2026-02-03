variable "environment" {
  type    = string
  default = "dev"
}
variable "instance_type" {
  type = string
  default = "t3.small.search"
}
variable "instance_count" {
  type = number
  default = 1
}
variable "volume_size" {
  type = number
  default = 20
}

