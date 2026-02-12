# Aurora PostgreSQL Stack - terraform-aws-modules/rds-aurora/aws wrapper

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
    key    = "vpc_production/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids  = try(data.terraform_remote_state.vpc.outputs.database_subnet_ids, try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, []))
  vpc_cidr    = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
}

resource "random_password" "master" {
  length  = 16
  special = false
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.0"

  name           = "${local.name_prefix}-aurora"
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_class = var.instance_class
  instances      = { 1 = {}, 2 = {} }

  vpc_id                 = local.vpc_id
  create_db_subnet_group = true
  subnets                = local.subnet_ids
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [local.vpc_cidr]
    }
  }

  master_username = "admin"
  master_password = random_password.master.result

  skip_final_snapshot = true
  deletion_protection = false

  tags = { Environment = var.environment, Stack = "aurora_postgres", ManagedBy = "OpportunityPortal" }
}

output "cluster_endpoint" { value = module.aurora.cluster_endpoint }
output "cluster_reader_endpoint" { value = module.aurora.cluster_reader_endpoint }

