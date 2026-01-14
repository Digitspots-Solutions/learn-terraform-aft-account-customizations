# RDS PostgreSQL Stack (v2)
# Uses terraform-aws-modules/rds/aws wrapper
# 
# Features:
# - PostgreSQL with configurable size (small/medium/large)
# - Auto-generated password stored in Secrets Manager
# - Performance Insights enabled
# - Enhanced monitoring
# - Optional Multi-AZ

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  
  backend "s3" {}
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get VPC outputs
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "${var.vpc_stack}/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  # Fallbacks for destroy
  vpc_id                     = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
  vpc_cidr                   = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
  database_subnet_group_name = try(data.terraform_remote_state.vpc.outputs.database_subnet_group_name, null)
}

module "rds" {
  source = "../../modules/rds"

  name_prefix = local.name_prefix
  identifier  = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  size           = var.size

  database_name   = var.database_name
  master_username = var.master_username

  vpc_id               = local.vpc_id
  vpc_cidr             = local.vpc_cidr
  db_subnet_group_name = local.database_subnet_group_name

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  tags = {
    Environment = var.environment
    Stack       = "rds_postgres"
    ManagedBy   = "OpportunityPortal"
  }
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  value = module.rds.db_instance_address
}

output "db_instance_port" {
  value = module.rds.db_instance_port
}

output "db_credentials_secret_arn" {
  value = module.rds.db_credentials_secret_arn
}

output "db_instance_id" {
  value = module.rds.db_instance_id
}

