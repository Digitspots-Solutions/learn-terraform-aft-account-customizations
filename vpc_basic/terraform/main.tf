# VPC Basic Stack
# Uses terraform-aws-modules/vpc/aws directly
#
# Features:
# - 2 AZ VPC with public, private, and database subnets
# - Single NAT Gateway (cost-optimized for dev/test)
# - VPC Endpoints for S3 and DynamoDB


data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)
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

  # NAT Gateway - single (cost-optimized)
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Database subnet group
  create_database_subnet_group = true

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs


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
