# ECS Fargate Variables

variable "environment" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "enable_service_discovery" {
  type    = bool
  default = true
}

variable "fargate_spot_weight" {
  description = "Weight for Fargate Spot capacity (0-100)"
  type        = number
  default     = 0
}

