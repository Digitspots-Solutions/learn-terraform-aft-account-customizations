# RDS Module Wrapper
# Wraps terraform-aws-modules/rds/aws for standardized RDS instance creation

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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  identifier = var.identifier != "" ? var.identifier : "${var.name_prefix}-${var.engine}"
  
  # Engine-specific configurations
  engine_configs = {
    postgres = {
      engine         = "postgres"
      engine_version = "16.4"
      port           = 5432
      family         = "postgres16"
    }
    mysql = {
      engine         = "mysql"
      engine_version = "8.0"
      port           = 3306
      family         = "mysql8.0"
    }
    mariadb = {
      engine         = "mariadb"
      engine_version = "10.11"
      port           = 3306
      family         = "mariadb10.11"
    }
  }
  
  engine_config = local.engine_configs[var.engine]
  
  # Size configurations
  size_configs = {
    small = {
      instance_class    = "db.t3.medium"
      allocated_storage = 20
      max_storage       = 100
    }
    medium = {
      instance_class    = "db.r6g.large"
      allocated_storage = 100
      max_storage       = 500
    }
    large = {
      instance_class    = "db.r6g.xlarge"
      allocated_storage = 200
      max_storage       = 1000
    }
  }
  
  size_config = local.size_configs[var.size]
}

# Generate random password if not provided
resource "random_password" "master" {
  count   = var.master_password == "" ? 1 : 0
  length  = 20
  special = false
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.identifier}-credentials"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Module = "rds"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = var.master_password != "" ? var.master_password : random_password.master[0].result
    host     = module.rds.db_instance_address
    port     = local.engine_config.port
    database = var.database_name
    engine   = var.engine
  })
}

# Security Group for RDS
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.identifier}-sg"
  description = "Security group for ${local.identifier} RDS"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = local.engine_config.port
      to_port     = local.engine_config.port
      protocol    = "tcp"
      description = "${var.engine} access from VPC"
      cidr_blocks = var.vpc_cidr
    }
  ]

  tags = var.tags
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.identifier

  # Engine
  engine               = local.engine_config.engine
  engine_version       = var.engine_version != "" ? var.engine_version : local.engine_config.engine_version
  family               = local.engine_config.family
  major_engine_version = split(".", var.engine_version != "" ? var.engine_version : local.engine_config.engine_version)[0]

  # Instance
  instance_class        = var.instance_class != "" ? var.instance_class : local.size_config.instance_class
  allocated_storage     = var.allocated_storage != 0 ? var.allocated_storage : local.size_config.allocated_storage
  max_allocated_storage = var.max_allocated_storage != 0 ? var.max_allocated_storage : local.size_config.max_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password != "" ? var.master_password : random_password.master[0].result
  port     = local.engine_config.port

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [module.security_group.security_group_id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.multi_az

  # Maintenance
  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period

  # Monitoring
  monitoring_interval                   = 60
  monitoring_role_name                  = "${local.identifier}-monitoring-role"
  create_monitoring_role                = true
  enabled_cloudwatch_logs_exports       = var.engine == "postgres" ? ["postgresql", "upgrade"] : ["error", "slowquery"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(var.tags, {
    Module      = "rds"
    ManagedBy   = "OpportunityPortal"
    Engine      = var.engine
    Environment = var.size
  })
}

