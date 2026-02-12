# API Gateway Stack - terraform-aws-modules/apigateway-v2/aws wrapper

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 4.0"

  name          = "${local.name_prefix}-api"
  description   = "HTTP API Gateway"
  protocol_type = "HTTP"


  cors_configuration = {
    allow_headers = ["content-type", "authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"]
  }

  tags = { Environment = var.environment, Stack = "api_gateway", ManagedBy = "OpportunityPortal" }
}

output "api_endpoint" { value = module.api_gateway.apigatewayv2_api_api_endpoint }
output "api_id" { value = module.api_gateway.apigatewayv2_api_id }

