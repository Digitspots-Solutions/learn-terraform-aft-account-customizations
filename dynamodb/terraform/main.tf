# DynamoDB Table Stack
# Uses terraform-aws-modules/dynamodb-table/aws directly
#
# Features:
# - On-demand or provisioned capacity
# - Point-in-time recovery enabled
# - Server-side encryption
# - Optional TTL and streams

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
  table_name  = var.table_name != "" ? var.table_name : "${local.name_prefix}-table"
}

module "dynamodb" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name     = local.table_name
  hash_key = var.hash_key
  range_key = var.range_key != "" ? var.range_key : null

  attributes = var.attributes

  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true

  ttl_enabled        = var.ttl_attribute_name != ""
  ttl_attribute_name = var.ttl_attribute_name != "" ? var.ttl_attribute_name : null

  stream_enabled   = var.enable_stream
  stream_view_type = var.enable_stream ? var.stream_view_type : null

  global_secondary_indexes = var.global_secondary_indexes

  tags = {
    Environment = var.environment
    Stack       = "dynamodb"
    ManagedBy   = "OpportunityPortal"
  }

  server_side_encryption_kms_key_arn = null
}

output "table_name" {
  value = module.dynamodb.dynamodb_table_id
}

output "table_arn" {
  value = module.dynamodb.dynamodb_table_arn
}

output "table_id" {
  value = module.dynamodb.dynamodb_table_id
}

output "table_stream_arn" {
  value = try(module.dynamodb.dynamodb_table_stream_arn, "")
}
