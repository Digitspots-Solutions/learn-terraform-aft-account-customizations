variable "environment" {
  type    = string
  default = "dev"
}
variable "domain_name" { type = string; default = "example.com"; description = "Domain name for hosted zone" }

