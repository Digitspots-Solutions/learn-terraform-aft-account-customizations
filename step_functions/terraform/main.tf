# Step Functions Stack - terraform-aws-modules/step-functions/aws wrapper

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

module "step_function" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "~> 4.0"

  name = "${local.name_prefix}-workflow"

  definition = jsonencode({
    Comment = "Sample workflow"
    StartAt = "HelloWorld"
    States = {
      HelloWorld = {
        Type   = "Pass"
        Result = "Hello, World!"
        End    = true
      }
    }
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  tags = { Environment = var.environment, Stack = "step_functions", ManagedBy = "OpportunityPortal" }
}

output "state_machine_arn" { value = module.step_function.state_machine_arn }

