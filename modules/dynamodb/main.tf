# DynamoDB Module Wrapper
# Wraps terraform-aws-modules/dynamodb-table/aws for standardized DynamoDB tables

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
  table_name = var.table_name != "" ? var.table_name : "${var.name_prefix}-table"
}

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name     = local.table_name
  hash_key = var.hash_key
  range_key = var.range_key != "" ? var.range_key : null

  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Table class
  table_class = var.table_class

  # Attributes
  attributes = var.attributes

  # Global Secondary Indexes
  global_secondary_indexes = var.global_secondary_indexes

  # Local Secondary Indexes
  local_secondary_indexes = var.local_secondary_indexes

  # Encryption
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = var.kms_key_arn

  # Point-in-time recovery
  point_in_time_recovery_enabled = var.enable_point_in_time_recovery

  # TTL
  ttl_enabled        = var.ttl_attribute_name != ""
  ttl_attribute_name = var.ttl_attribute_name

  # Stream
  stream_enabled   = var.enable_stream
  stream_view_type = var.enable_stream ? var.stream_view_type : null

  # Autoscaling
  autoscaling_enabled = var.billing_mode == "PROVISIONED" && var.enable_autoscaling

  autoscaling_read = var.enable_autoscaling ? {
    scale_in_cooldown  = 50
    scale_out_cooldown = 50
    target_value       = 70
    max_capacity       = var.read_capacity * 10
  } : null

  autoscaling_write = var.enable_autoscaling ? {
    scale_in_cooldown  = 50
    scale_out_cooldown = 50
    target_value       = 70
    max_capacity       = var.write_capacity * 10
  } : null

  # Replica regions for global tables
  replica_regions = var.replica_regions

  tags = merge(var.tags, {
    Module    = "dynamodb"
    ManagedBy = "OpportunityPortal"
  })
}

