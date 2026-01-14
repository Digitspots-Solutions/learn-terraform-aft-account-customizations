# KMS Key Stack
# Uses terraform-aws-modules/kms/aws
# 
# Features:
# - Customer managed key
# - Automatic key rotation
# - Configurable key policy

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

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  # Aliases
  aliases = ["${local.name_prefix}/${var.key_alias}"]

  # Key policy - allow account-level access
  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  
  key_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]

  tags = {
    Environment = var.environment
    Stack       = "kms"
    ManagedBy   = "OpportunityPortal"
  }
}

output "key_id" {
  value = module.kms.key_id
}

output "key_arn" {
  value = module.kms.key_arn
}

output "key_alias_arn" {
  value = module.kms.aliases["${local.name_prefix}/${var.key_alias}"].arn
}

