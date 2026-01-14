# Lambda + API Gateway Stack
# Uses terraform-aws-modules/lambda/aws wrapper
# 
# Features:
# - Lambda function with HTTP API Gateway
# - CORS enabled
# - CloudWatch Logs
# - X-Ray tracing

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

module "lambda" {
  source = "../../modules/lambda"

  name_prefix   = local.name_prefix
  function_name = var.function_name
  description   = var.description

  language     = var.language
  handler      = var.handler
  architecture = "arm64"

  memory_size = var.memory_size
  timeout     = var.timeout

  environment_variables = var.environment_variables

  enable_xray        = true
  log_retention_days = 14

  # Create API Gateway
  create_api_gateway = true
  cors_origins       = var.cors_origins

  tags = {
    Environment = var.environment
    Stack       = "lambda_api"
    ManagedBy   = "OpportunityPortal"
  }
}

output "function_name" {
  value = module.lambda.function_name
}

output "function_arn" {
  value = module.lambda.function_arn
}

output "api_endpoint" {
  value = module.lambda.api_endpoint
}

output "api_id" {
  value = module.lambda.api_id
}

