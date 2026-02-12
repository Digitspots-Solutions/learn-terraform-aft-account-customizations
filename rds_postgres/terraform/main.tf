# RDS PostgreSQL Stack
# Uses terraform-aws-modules/rds/aws directly
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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "${var.vpc_stack}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  identifier  = var.identifier != "" ? var.identifier : "${local.name_prefix}-postgres"

  vpc_id                     = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
  vpc_cidr                   = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
  database_subnet_group_name = try(data.terraform_remote_state.vpc.outputs.database_subnet_group_name, null)

  size_configs = {
    small  = { instance_class = "db.t3.medium",  allocated = 20,  max = 100  }
    medium = { instance_class = "db.r6g.large",   allocated = 100, max = 500  }
    large  = { instance_class = "db.r6g.xlarge",  allocated = 200, max = 1000 }
  }

  size_config = local.size_configs[var.size]
}

resource "random_password" "master" {
  length  = 20
  special = false
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.identifier}-sg"
  description = "Security group for ${local.identifier} RDS"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from VPC"
      cidr_blocks = local.vpc_cidr
    }
  ]

  tags = {
    Environment = var.environment
    ManagedBy   = "OpportunityPortal"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.identifier

  engine               = "postgres"
  engine_version       = var.engine_version != "" ? var.engine_version : "16.4"
  family               = "postgres16"
  major_engine_version = "16"

  instance_class        = local.size_config.instance_class
  allocated_storage     = local.size_config.allocated
  max_allocated_storage = local.size_config.max
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = local.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]
  publicly_accessible    = false

  multi_az = var.multi_az

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  monitoring_interval                   = 60
  monitoring_role_name                  = "${local.identifier}-monitoring-role"
  create_monitoring_role                = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = {
    Environment = var.environment
    Stack       = "rds_postgres"
    ManagedBy   = "OpportunityPortal"
  }
}

# Store credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.identifier}-credentials"
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
    ManagedBy   = "OpportunityPortal"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = module.rds.db_instance_address
    port     = 5432
    database = var.database_name
    engine   = "postgres"
  })
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
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_instance_id" {
  value = module.rds.db_instance_identifier
}
