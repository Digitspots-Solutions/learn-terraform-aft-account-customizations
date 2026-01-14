# S3 Bucket Stack
# Uses terraform-aws-modules/s3-bucket/aws

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.name_prefix}-data-${data.aws_region.current.name}"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = true

  tags = {
    Environment = var.environment
    Stack       = "s3_bucket"
    ManagedBy   = "OpportunityPortal"
  }
}

output "bucket_id" { value = module.s3_bucket.s3_bucket_id }
output "bucket_arn" { value = module.s3_bucket.s3_bucket_arn }

