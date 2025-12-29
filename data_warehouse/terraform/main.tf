data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "baseline_networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_redshift_subnet_group" "main" {
  name       = var.cluster_name
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
}

resource "aws_security_group" "redshift" {
  name   = "${var.cluster_name}-redshift"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }
}

resource "aws_redshift_cluster" "main" {
  cluster_identifier        = var.cluster_name
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = random_password.redshift.result
  node_type                 = var.node_type
  cluster_type              = "multi-node"
  number_of_nodes           = var.number_of_nodes
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  skip_final_snapshot       = true
  encrypted                 = true
}

resource "random_password" "redshift" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Redshift doesn't allow: / @ " ' space
}

resource "aws_secretsmanager_secret" "redshift" {
  name = "${var.cluster_name}-password"
}

resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id     = aws_secretsmanager_secret.redshift.id
  secret_string = random_password.redshift.result
}

data "aws_caller_identity" "current" {}
