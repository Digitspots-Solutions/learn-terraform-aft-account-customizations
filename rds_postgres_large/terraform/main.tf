data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "baseline_networking/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  db_name_unique = "${var.db_name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.db_name_unique}-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name   = "${local.db_name_unique}-rds"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = local.db_name_unique
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = var.instance_class
  allocated_storage      = var.storage_gb
  storage_encrypted      = true
  username               = var.master_username
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = var.skip_final_snapshot
  multi_az               = var.multi_az
  backup_retention_period = 7
}

resource "random_password" "db" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${local.db_name_unique}-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}
