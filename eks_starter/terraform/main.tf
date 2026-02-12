# EKS Starter Stack
# Uses terraform-aws-modules/eks/aws directly
#
# Features:
# - Development Kubernetes cluster
# - Managed node group with t3.medium
# - Core addons (CoreDNS, kube-proxy, VPC CNI)
# - IRSA enabled



data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix        = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  cluster_name       = var.cluster_name != "" ? var.cluster_name : "${local.name_prefix}-eks"
  vpc_id             = try(data.terraform_remote_state.vpc.outputs.vpc_id, "vpc-placeholder")
  private_subnet_ids = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  cluster_endpoint_public_access = true

  # Addons
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  # Managed node group
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

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
  value = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks.cluster_name}"
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
