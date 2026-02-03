# OpenSearch Stack - terraform-aws-modules/opensearch/aws wrapper

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

resource "null_resource" "opensearch_slr" {
  provisioner "local-exec" {
    command = "aws iam create-service-linked-role --service-name opensearchservice.amazonaws.com || echo 'SLR already exists or error occurred'"
  }
}

# Small delay to ensure role propagation
resource "time_sleep" "wait_for_slr" {
  depends_on = [null_resource.opensearch_slr]
  create_duration = "10s"
}

resource "aws_security_group" "opensearch" {
  name   = "${local.name_prefix}-opensearch-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-opensearch-sg" }
}

resource "aws_opensearch_domain" "main" {
  depends_on     = [time_sleep.wait_for_slr]
  domain_name    = replace("${local.name_prefix}-search", "_", "-")
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = var.instance_type
    instance_count = var.instance_count
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  vpc_options {
    subnet_ids         = [local.subnet_ids[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = { Environment = var.environment, Stack = "opensearch", ManagedBy = "OpportunityPortal" }
}

output "domain_endpoint" { value = aws_opensearch_domain.main.endpoint }
output "domain_arn" { value = aws_opensearch_domain.main.arn }

