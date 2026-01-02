data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "baseline_networking/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  # Use last 8 chars of account ID for unique but short names
  account_short = substr(data.aws_caller_identity.current.account_id, -8, 8)
  region_short  = replace(replace(data.aws_region.current.name, "us-", ""), "west-", "w")
  
  # Safe lookups with fallbacks for destroy operations when network is already gone
  private_subnet_ids = try(data.terraform_remote_state.network.outputs.private_subnet_ids, [])
  public_subnet_ids  = try(data.terraform_remote_state.network.outputs.public_subnet_ids, [])
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"  # Latest stable - Jan 2026
  vpc_config {
    subnet_ids = concat(local.public_subnet_ids, local.private_subnet_ids)
  }
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cl-${local.account_short}-${local.region_short}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-nd-${local.account_short}-${local.region_short}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-ng-${local.account_short}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids
  instance_types  = [var.instance_type]
  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_count + 2
    min_size     = var.node_count
  }
  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_registry
  ]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
