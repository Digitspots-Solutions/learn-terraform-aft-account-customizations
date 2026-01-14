# Lambda Module Wrapper
# Wraps terraform-aws-modules/lambda/aws for standardized Lambda function creation

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
  function_name = var.function_name != "" ? var.function_name : "${var.name_prefix}-lambda"
  
  # Runtime configurations
  runtime_configs = {
    python     = "python3.12"
    nodejs     = "nodejs20.x"
    go         = "provided.al2023"
    java       = "java21"
    dotnet     = "dotnet8"
  }
  
  runtime = var.runtime != "" ? var.runtime : local.runtime_configs[var.language]
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = local.function_name
  description   = var.description
  handler       = var.handler
  runtime       = local.runtime
  architectures = [var.architecture]

  # Source code
  source_path = var.source_path
  hash_extra  = var.hash_extra

  # Or use S3/container
  create_package = var.source_path != "" ? true : false
  s3_bucket      = var.s3_bucket
  s3_key         = var.s3_key
  image_uri      = var.image_uri

  # Memory & timeout
  memory_size = var.memory_size
  timeout     = var.timeout

  # Concurrency
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Environment variables
  environment_variables = var.environment_variables

  # VPC configuration (optional)
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  attach_network_policy  = length(var.vpc_subnet_ids) > 0

  # Logging
  cloudwatch_logs_retention_in_days = var.log_retention_days
  attach_cloudwatch_logs_policy     = true

  # X-Ray tracing
  tracing_mode = var.enable_xray ? "Active" : "PassThrough"
  attach_tracing_policy = var.enable_xray

  # Dead letter queue
  dead_letter_target_arn = var.dead_letter_queue_arn

  # Layers
  layers = var.layers

  # IAM
  attach_policy_json = var.policy_json != ""
  policy_json        = var.policy_json

  attach_policy_statements = length(var.policy_statements) > 0
  policy_statements        = var.policy_statements

  attach_policies    = length(var.policy_arns) > 0
  policies           = var.policy_arns
  number_of_policies = length(var.policy_arns)

  # Event source mappings (SQS, DynamoDB, Kinesis)
  event_source_mapping = var.event_source_mapping

  # Allowed triggers
  allowed_triggers = var.allowed_triggers

  tags = merge(var.tags, {
    Module      = "lambda"
    ManagedBy   = "OpportunityPortal"
    Language    = var.language
  })
}

# API Gateway integration (optional)
module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"
  count   = var.create_api_gateway ? 1 : 0

  name          = "${local.function_name}-api"
  description   = "API Gateway for ${local.function_name}"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
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

  tags = var.tags
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  count = var.create_api_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway[0].api_execution_arn}/*/*"
}

