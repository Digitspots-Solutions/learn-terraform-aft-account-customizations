# RDS MySQL Stack - terraform-aws-modules/rds/aws wrapper

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix  = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id       = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids   = try(data.terraform_remote_state.vpc.outputs.database_subnet_ids, try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, []))
  vpc_cidr     = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
}

resource "random_password" "master" {
  length  = 16
  special = false
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-mysql"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = "appdb"
  username = "admin"
  password = random_password.master.result
  port     = 3306

  multi_az               = var.multi_az
  vpc_id                 = local.vpc_id
  db_subnet_group_name   = module.rds.db_subnet_group_id
  vpc_security_group_ids = [aws_security_group.rds.id]
  create_db_subnet_group = true
  subnet_ids             = local.subnet_ids

  skip_final_snapshot = true
  deletion_protection = false

  tags = { Environment = var.environment, Stack = "rds_mysql", ManagedBy = "OpportunityPortal" }
}

resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-mysql-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-mysql-sg" }
}

output "db_endpoint" { value = module.rds.db_instance_endpoint }
output "db_name" { value = module.rds.db_instance_name }

