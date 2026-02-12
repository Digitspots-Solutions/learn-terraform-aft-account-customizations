# SQS Queue Stack
# Uses terraform-aws-modules/sqs/aws directly
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
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  queue_name  = var.queue_name != "" ? var.queue_name : "${local.name_prefix}-queue"
  full_name   = var.fifo ? "${local.queue_name}.fifo" : local.queue_name
}

# Dead letter queue
module "dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  count = var.create_dlq ? 1 : 0

  name = var.fifo ? "${local.queue_name}-dlq.fifo" : "${local.queue_name}-dlq"

  fifo_queue                  = var.fifo
  content_based_deduplication = var.content_based_deduplication
  sqs_managed_sse_enabled     = true

  tags = {
    Environment = var.environment
    Stack       = "sqs"
    ManagedBy   = "OpportunityPortal"
  }
}

# Main queue
module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name = local.full_name

  fifo_queue                  = var.fifo
  content_based_deduplication = var.content_based_deduplication
  sqs_managed_sse_enabled     = true

  delay_seconds              = var.delay_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = module.dlq[0].queue_arn
    maxReceiveCount     = var.max_receive_count
  }) : null

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
  value = var.create_dlq ? module.dlq[0].queue_url : ""
}

output "dlq_arn" {
  value = var.create_dlq ? module.dlq[0].queue_arn : ""
}
