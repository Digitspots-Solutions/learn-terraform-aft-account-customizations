# ElastiCache Redis Stack - terraform-aws-modules/elasticache/aws wrapper

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids  = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
  vpc_cidr    = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
}

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  cluster_id               = "${local.name_prefix}-redis"
  create_cluster           = true
  create_replication_group = false

  engine         = "redis"
  engine_version = "7.0"
  node_type      = var.node_type

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  security_group_rules = {
    ingress_vpc = {
      cidr_ipv4 = local.vpc_cidr
    }
  }

  tags = { Environment = var.environment, Stack = "elasticache_redis", ManagedBy = "OpportunityPortal" }
}

output "cache_endpoint" { value = module.elasticache.cluster_cache_nodes }

