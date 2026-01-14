# SNS Topic Stack
# Uses terraform-aws-modules/sns/aws
# 
# Features:
# - SNS topic with server-side encryption
# - Optional FIFO topic
# - Configurable subscriptions

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

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  topic_name  = var.topic_name != "" ? var.topic_name : "${local.name_prefix}-topic"
}

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  name              = var.fifo ? "${local.topic_name}.fifo" : local.topic_name
  fifo_topic        = var.fifo
  content_based_deduplication = var.fifo

  # Encryption
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Environment = var.environment
    Stack       = "sns"
    ManagedBy   = "OpportunityPortal"
  }
}

output "topic_arn" {
  value = module.sns.topic_arn
}

output "topic_name" {
  value = local.topic_name
}

