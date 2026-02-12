# Lambda + API Gateway Stack
# Uses terraform-aws-modules/lambda/aws + apigateway-v2/aws directly
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
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix   = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  function_name = var.function_name != "" ? var.function_name : "${local.name_prefix}-api"
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = local.function_name
  description   = var.description
  handler       = var.handler
  runtime       = "python3.12"
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

  allowed_triggers = {
    AllowAPIGatewayInvoke = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
    Stack       = "lambda_api"
    ManagedBy   = "OpportunityPortal"
  }
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = "${local.function_name}-api"
  description   = "API Gateway for ${local.function_name}"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    allow_methods = ["*"]
    allow_origins = var.cors_origins
  }

  routes = {
    "ANY /{proxy+}" = {
      integration = {
        uri                    = module.lambda.lambda_function_arn
        type                   = "AWS_PROXY"
        payload_format_version = "2.0"
      }
    }
    "$default" = {
      integration = {
        uri                    = module.lambda.lambda_function_arn
        type                   = "AWS_PROXY"
        payload_format_version = "2.0"
      }
    }
  }

  tags = {
    Environment = var.environment
    Stack       = "lambda_api"
    ManagedBy   = "OpportunityPortal"
  }
}

output "function_name" {
  value = module.lambda.lambda_function_name
}

output "function_arn" {
  value = module.lambda.lambda_function_arn
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "api_id" {
  value = module.api_gateway.id
}
