variable "environment" {
  type    = string
  default = "dev"
}
variable "instance_class" {
  type = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type = number
  default = 20
}
variable "max_allocated_storage" {
  type = number
  default = 100
}
variable "multi_az" {
  type = bool
  default = false
}

