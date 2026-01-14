variable "environment" { type = string; default = "dev" }
variable "instance_type" { type = string; default = "t3.micro" }
variable "min_size" { type = number; default = 1 }
variable "max_size" { type = number; default = 3 }
variable "desired_capacity" { type = number; default = 1 }

