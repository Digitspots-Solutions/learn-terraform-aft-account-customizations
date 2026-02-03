# DynamoDB Table Stack
# Uses terraform-aws-modules/dynamodb-table/aws wrapper
# 
# Features:
# - On-demand or provisioned capacity
# - Point-in-time recovery enabled
# - Server-side encryption
# - Optional TTL
# - Optional streams

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

module "dynamodb" {
  source = "../../modules/dynamodb"

  name_prefix = local.name_prefix
  table_name  = var.table_name

  hash_key  = var.hash_key
  range_key = var.range_key

  attributes = var.attributes

  billing_mode   = var.billing_mode
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  enable_point_in_time_recovery = true
  ttl_attribute_name            = var.ttl_attribute_name

  enable_stream   = var.enable_stream
  stream_view_type = var.stream_view_type

  global_secondary_indexes = var.global_secondary_indexes

  tags = {
    Environment = var.environment
    Stack       = "dynamodb"
    ManagedBy   = "OpportunityPortal"
  }

  kms_key_arn = null
}

output "table_name" {
  value = module.dynamodb.table_name
}

output "table_arn" {
  value = module.dynamodb.table_arn
}

output "table_id" {
  value = module.dynamodb.table_id
}

output "table_stream_arn" {
  value = module.dynamodb.table_stream_arn
}

