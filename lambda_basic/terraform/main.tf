# Lambda Basic Stack
# Uses terraform-aws-modules/lambda/aws wrapper
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
  
  backend "s3" {}
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "lambda" {
  source = "../../modules/lambda"

  name_prefix   = local.name_prefix
  function_name = var.function_name
  description   = var.description

  language     = var.language
  handler      = var.handler
  architecture = var.architecture

  memory_size = var.memory_size
  timeout     = var.timeout

  environment_variables = var.environment_variables

  enable_xray        = true
  log_retention_days = 14

  create_api_gateway = false

  tags = {
    Environment = var.environment
    Stack       = "lambda_basic"
    ManagedBy   = "OpportunityPortal"
  }
}

output "function_name" {
  value = module.lambda.function_name
}

output "function_arn" {
  value = module.lambda.function_arn
}

output "role_arn" {
  value = module.lambda.role_arn
}

output "cloudwatch_log_group_name" {
  value = module.lambda.cloudwatch_log_group_name
}

