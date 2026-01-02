data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get the latest available PostgreSQL 16.x version in this region
data "aws_rds_engine_version" "postgres" {
  engine             = "postgres"
  preferred_versions = ["16.6", "16.5", "16.4", "16.3", "16.2", "16.1", "15.8", "15.7", "15.6"]
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "baseline_networking/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  db_name_unique = "${var.db_name}-${data.aws_caller_identity.current.account_id}"
  
  # Safe lookups with fallbacks for destroy operations when network is already gone
  vpc_id             = try(data.terraform_remote_state.network.outputs.vpc_id, "")
  vpc_cidr           = try(data.terraform_remote_state.network.outputs.vpc_cidr, "10.0.0.0/16")
  private_subnet_ids = try(data.terraform_remote_state.network.outputs.private_subnet_ids, [])
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.db_name_unique}-subnet-group"
  subnet_ids = local.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name   = "${local.db_name_unique}-rds"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = local.db_name_unique
  engine                  = "postgres"
  engine_version          = data.aws_rds_engine_version.postgres.version
  instance_class          = var.instance_class
  allocated_storage       = var.storage_gb
  storage_encrypted       = true
  username                = var.master_username
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = var.skip_final_snapshot
  multi_az                = var.multi_az
  backup_retention_period = 7
}

resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # RDS doesn't allow: / @ " space
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.db_name_unique}-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}
