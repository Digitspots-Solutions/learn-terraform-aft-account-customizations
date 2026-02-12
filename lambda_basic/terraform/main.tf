# Lambda Basic Stack
# Uses terraform-aws-modules/lambda/aws directly
#
# Features:
# - Single Lambda function
# - CloudWatch Logs
# - X-Ray tracing enabled
# - ARM64 architecture (cost-optimized)

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
  name_prefix   = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  function_name = var.function_name != "" ? var.function_name : "${local.name_prefix}-lambda"
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = local.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  architectures = ["arm64"]

  create_package = false
  publish        = true

  memory_size = var.memory_size
  timeout     = var.timeout

  environment_variables = var.environment_variables

  # Logging
  cloudwatch_logs_retention_in_days = 14
  attach_cloudwatch_logs_policy     = true

  # X-Ray tracing
  tracing_mode          = "Active"
  attach_tracing_policy = true

  tags = {
    Environment = var.environment
    Stack       = "lambda_basic"
    ManagedBy   = "OpportunityPortal"
  }
}

output "function_name" {
  value = module.lambda.lambda_function_name
}

output "function_arn" {
  value = module.lambda.lambda_function_arn
}

output "role_arn" {
  value = module.lambda.lambda_role_arn
}

output "cloudwatch_log_group_name" {
  value = module.lambda.lambda_cloudwatch_log_group_name
}
