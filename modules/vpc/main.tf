# VPC Module Wrapper
# Wraps terraform-aws-modules/vpc/aws for standardized VPC creation

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  # Generate CIDR blocks for subnets
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + var.az_count)]
  database_subnets = var.create_database_subnets ? [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + (var.az_count * 2))] : []
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs              = local.azs
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs
  flow_log_max_aggregation_interval    = 60

  # Database subnet group
  create_database_subnet_group       = var.create_database_subnets
  create_database_subnet_route_table = var.create_database_subnets

  # Tags for EKS if needed
  public_subnet_tags = var.eks_cluster_name != "" ? {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  } : {}

  private_subnet_tags = var.eks_cluster_name != "" ? {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  } : {}

  tags = merge(var.tags, {
    Module    = "vpc"
    ManagedBy = "OpportunityPortal"
  })
}

# VPC Endpoints (optional)
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"
  count   = var.enable_vpc_endpoints ? 1 : 0

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.name}-s3-endpoint" }
    }
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.name}-dynamodb-endpoint" }
    }
  }

  tags = var.tags
}

