# ECS Fargate Stack
# Uses terraform-aws-modules/ecs/aws directly
#
# Features:
# - Serverless container cluster
# - Fargate and Fargate Spot capacity providers
# - Container Insights enabled
# - Service Discovery namespace
# - Task execution role

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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix  = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${local.name_prefix}-ecs"
  vpc_id       = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = local.cluster_name

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = var.fargate_spot_weight > 0 ? 100 - var.fargate_spot_weight : 100
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = var.fargate_spot_weight
      }
    }
  }

  # Container Insights
  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Stack       = "ecs_fargate"
    ManagedBy   = "OpportunityPortal"
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0

  name        = "${local.cluster_name}.local"
  description = "Service discovery namespace for ${local.cluster_name}"
  vpc         = local.vpc_id

  tags = {
    Environment = var.environment
    ManagedBy   = "OpportunityPortal"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.cluster_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "OpportunityPortal"
  }
}

output "cluster_name" {
  value = module.ecs.cluster_name
}

output "cluster_arn" {
  value = module.ecs.cluster_arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "service_discovery_namespace_id" {
  value = try(aws_service_discovery_private_dns_namespace.main[0].id, "")
}
