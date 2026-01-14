# ACM Certificate Stack
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "route53" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "route53_zone/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  zone_id = try(data.terraform_remote_state.route53.outputs.zone_id, "")
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name         = var.domain_name
  zone_id             = local.zone_id
  validation_method   = "DNS"
  wait_for_validation = true

  tags = {
    Environment = var.environment
    Stack       = "acm_certificate"
    ManagedBy   = "OpportunityPortal"
  }
}

output "certificate_arn" { value = module.acm.acm_certificate_arn }

