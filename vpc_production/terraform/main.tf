# VPC Production Stack
# Uses terraform-aws-modules/vpc/aws directly
#
# Features:
# - 3 AZ VPC with public, private, and database subnets
# - NAT Gateway per AZ (HA for production)
# - VPC Flow Logs enabled
# - VPC Endpoints for S3 and DynamoDB

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
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  azs         = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr    = var.vpc_cidr
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = local.vpc_cidr
  azs  = local.azs

  # Subnet CIDRs
  public_subnets   = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 8, i)]
  private_subnets  = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 8, i + 10)]
  database_subnets = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 8, i + 20)]

  # NAT Gateway - one per AZ for HA
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # Database subnet group
  create_database_subnet_group = true

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs - always on for production
  enable_flow_log                      = true


  tags = {
    Environment = var.environment
    Stack       = "vpc_production"
    ManagedBy   = "OpportunityPortal"
  }
}

# Outputs for dependent stacks
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "database_subnet_ids" {
  value = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "availability_zones" {
  value = local.azs
}
