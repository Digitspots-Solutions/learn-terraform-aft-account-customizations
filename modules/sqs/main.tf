# SQS Module Wrapper
# Wraps terraform-aws-modules/sqs/aws for standardized SQS queue creation
# Uses the module's NATIVE DLQ support - no separate module needed!

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  queue_name = var.queue_name != "" ? var.queue_name : "${var.name_prefix}-queue"
  # FIFO queues must end with .fifo
  full_queue_name = var.fifo ? "${local.queue_name}.fifo" : local.queue_name
}

module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name = local.full_queue_name

  # FIFO settings
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo && var.content_based_deduplication

  # Message settings
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Encryption
  sqs_managed_sse_enabled           = var.kms_key_id == ""
  kms_master_key_id                 = var.kms_key_id != "" ? var.kms_key_id : null
  kms_data_key_reuse_period_seconds = var.kms_key_id != "" ? 300 : null

  # Dead Letter Queue - use module's native support!
  create_dlq                    = var.create_dlq
  dlq_message_retention_seconds = 1209600 # 14 days
  redrive_policy = var.create_dlq ? {
    maxReceiveCount = var.max_receive_count
  } : {}

  tags = merge(var.tags, {
    Module    = "sqs"
    ManagedBy = "OpportunityPortal"
  })
}
