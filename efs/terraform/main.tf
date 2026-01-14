# EFS (Elastic File System) Stack
# Shared file storage for containers and instances
#
# Features:
# - Encrypted at rest with KMS
# - Multi-AZ mount targets
# - Automatic backups
# - Access points for container integration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  # Backend configured by buildspec.yml at runtime
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get VPC outputs from vpc_basic stack
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids  = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
  vpc_cidr    = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
}

# Security group for EFS mount targets
resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs-sg"
  description = "Allow NFS traffic from VPC"
  vpc_id      = local.vpc_id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-efs-sg"
    Environment = var.environment
    Stack       = "efs"
    ManagedBy   = "OpportunityPortal"
  }
}

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "${local.name_prefix}-efs"
  encrypted      = true

  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput : null

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "${local.name_prefix}-efs"
    Environment = var.environment
    Stack       = "efs"
    ManagedBy   = "OpportunityPortal"
  }
}

# Mount targets in each private subnet
resource "aws_efs_mount_target" "main" {
  count = length(local.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = local.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Backup policy
resource "aws_efs_backup_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = var.enable_backups ? "ENABLED" : "DISABLED"
  }
}

# Access point for containers (optional)
resource "aws_efs_access_point" "main" {
  count = var.create_access_point ? 1 : 0

  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "${local.name_prefix}-efs-ap"
    Environment = var.environment
    Stack       = "efs"
    ManagedBy   = "OpportunityPortal"
  }
}

# Outputs
output "file_system_id" {
  value       = aws_efs_file_system.main.id
  description = "EFS file system ID"
}

output "file_system_arn" {
  value       = aws_efs_file_system.main.arn
  description = "EFS file system ARN"
}

output "file_system_dns_name" {
  value       = aws_efs_file_system.main.dns_name
  description = "EFS DNS name for mounting"
}

output "security_group_id" {
  value       = aws_security_group.efs.id
  description = "Security group ID for EFS"
}

output "access_point_id" {
  value       = var.create_access_point ? aws_efs_access_point.main[0].id : null
  description = "EFS access point ID (if created)"
}

