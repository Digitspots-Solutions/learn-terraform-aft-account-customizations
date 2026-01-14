# EKS Module Wrapper
# Wraps terraform-aws-modules/eks/aws for standardized EKS cluster creation

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${var.name_prefix}-eks"
  
  # Node group configurations based on environment
  node_groups = {
    starter = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
    }
    development = {
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      disk_size      = 50
    }
    production = {
      min_size       = 3
      max_size       = 10
      desired_size   = 3
      instance_types = ["m6i.xlarge", "m5.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
    }
  }
  
  selected_config = local.node_groups[var.environment]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # Networking
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Cluster access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  # Authentication
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  # Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  # Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name           = "${local.cluster_name}-main"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = local.selected_config.instance_types
      capacity_type  = local.selected_config.capacity_type

      min_size     = local.selected_config.min_size
      max_size     = local.selected_config.max_size
      desired_size = local.selected_config.desired_size

      disk_size = local.selected_config.disk_size

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = merge(var.tags, {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
      })
    }
  }

  # Cluster security group additional rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group additional rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  tags = merge(var.tags, {
    Module      = "eks"
    ManagedBy   = "OpportunityPortal"
    Environment = var.environment
  })
}

# IRSA for VPC CNI
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${local.cluster_name}-vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

# IRSA for EBS CSI Driver
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${local.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

