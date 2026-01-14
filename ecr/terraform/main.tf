# ECR (Elastic Container Registry) Stack
# Uses terraform-aws-modules/ecr/aws

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
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  repository_name = "${local.name_prefix}-app"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })

  repository_image_scan_on_push = true
  repository_force_delete       = true

  tags = {
    Environment = var.environment
    Stack       = "ecr"
    ManagedBy   = "OpportunityPortal"
  }
}

output "repository_url" { value = module.ecr.repository_url }
output "repository_arn" { value = module.ecr.repository_arn }

