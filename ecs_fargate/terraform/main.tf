# ECS Fargate Stack
# Uses terraform-aws-modules/ecs/aws wrapper
# 
# Features:
# - Serverless container cluster
# - Fargate and Fargate Spot capacity providers
# - Container Insights enabled
# - Service Discovery namespace
# - Task execution role with ECR/Secrets access

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

# Get VPC outputs from vpc_basic stack
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix  = local.name_prefix
  cluster_name = var.cluster_name

  vpc_id = local.vpc_id

  enable_container_insights = true
  enable_service_discovery  = var.enable_service_discovery
  fargate_spot_weight       = var.fargate_spot_weight

  log_retention_days = 30

  tags = {
    Environment = var.environment
    Stack       = "ecs_fargate"
    ManagedBy   = "OpportunityPortal"
  }
}

output "cluster_name" {
  value = module.ecs.cluster_name
}

output "cluster_arn" {
  value = module.ecs.cluster_arn
}

output "task_execution_role_arn" {
  value = module.ecs.task_execution_role_arn
}

output "log_group_name" {
  value = module.ecs.log_group_name
}

output "service_discovery_namespace_id" {
  value = module.ecs.service_discovery_namespace_id
}

