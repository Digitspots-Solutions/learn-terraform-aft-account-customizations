# SQS Queue Stack
# Uses terraform-aws-modules/sqs/aws wrapper
# 
# Features:
# - Standard or FIFO queue
# - Dead letter queue included
# - Server-side encryption
# - Long polling enabled

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
}

module "sqs" {
  source = "../../modules/sqs"

  name_prefix = local.name_prefix
  queue_name  = var.queue_name

  fifo                        = var.fifo
  content_based_deduplication = var.content_based_deduplication

  delay_seconds              = var.delay_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 10  # Long polling
  visibility_timeout_seconds = var.visibility_timeout_seconds

  create_dlq        = var.create_dlq
  max_receive_count = var.max_receive_count

  tags = {
    Environment = var.environment
    Stack       = "sqs"
    ManagedBy   = "OpportunityPortal"
  }
}

output "queue_url" {
  value = module.sqs.queue_url
}

output "queue_arn" {
  value = module.sqs.queue_arn
}

output "queue_name" {
  value = module.sqs.queue_name
}

output "dlq_url" {
  value = module.sqs.dlq_url
}

output "dlq_arn" {
  value = module.sqs.dlq_arn
}

