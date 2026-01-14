# VPC Basic Stack
# Uses terraform-aws-modules/vpc/aws wrapper
# 
# Features:
# - 2-3 AZ VPC with public and private subnets
# - Single NAT Gateway (cost-optimized for dev/test)
# - Database subnets included
# - VPC Endpoints for S3 and DynamoDB

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

provider "aws" {
  # Region configured via backend
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "vpc" {
  source = "../../modules/vpc"

  name     = "${local.name_prefix}-vpc"
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  # Cost-optimized settings for dev/test
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Database subnets for RDS/Aurora
  create_database_subnets = true

  # Observability
  enable_flow_logs = var.enable_flow_logs

  # VPC Endpoints (cost-free Gateway endpoints)
  enable_vpc_endpoints = true

  # EKS tagging if cluster name provided
  eks_cluster_name = var.eks_cluster_name

  tags = {
    Environment = var.environment
    Stack       = "vpc_basic"
    ManagedBy   = "OpportunityPortal"
  }
}

# Outputs for dependent stacks
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.vpc.database_subnet_ids
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "availability_zones" {
  value = module.vpc.availability_zones
}

