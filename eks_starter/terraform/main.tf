# EKS Starter Stack
# Uses terraform-aws-modules/eks/aws wrapper
# 
# Features:
# - Development Kubernetes cluster
# - 2 t3.medium nodes
# - Core addons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
# - IRSA enabled

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
    region = data.aws_region.current.name
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  # Fallback values for destroy operations
  vpc_id             = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
  private_subnet_ids = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
}

module "eks" {
  source = "../../modules/eks"

  name_prefix    = local.name_prefix
  cluster_name   = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  environment = "starter"

  cluster_endpoint_public_access = true

  tags = {
    Environment = var.environment
    Stack       = "eks_starter"
    ManagedBy   = "OpportunityPortal"
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "configure_kubectl" {
  value = module.eks.configure_kubectl
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

