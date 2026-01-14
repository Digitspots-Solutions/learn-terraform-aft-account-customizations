# EventBridge Stack - terraform-aws-modules/eventbridge/aws wrapper

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

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"

  bus_name = "${local.name_prefix}-events"

  create_bus = true

  tags = { Environment = var.environment, Stack = "eventbridge", ManagedBy = "OpportunityPortal" }
}

output "eventbridge_bus_name" { value = module.eventbridge.eventbridge_bus_name }
output "eventbridge_bus_arn" { value = module.eventbridge.eventbridge_bus_arn }

