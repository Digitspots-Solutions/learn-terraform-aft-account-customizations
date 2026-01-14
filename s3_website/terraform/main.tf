# S3 Static Website Stack
# Uses terraform-aws-modules/s3-bucket/aws
# 
# Features:
# - Static website hosting enabled
# - Optional CloudFront integration ready
# - Versioning enabled
# - Force destroy for easy cleanup

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  
  backend "s3" {}
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${local.name_prefix}-website"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = local.bucket_name

  # Website configuration
  website = {
    index_document = var.index_document
    error_document = var.error_document
  }

  # Versioning
  versioning = {
    enabled = var.enable_versioning
  }

  # Force destroy for easy cleanup
  force_destroy = true

  # Block public access (use CloudFront OAC instead)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Environment = var.environment
    Stack       = "s3_website"
    ManagedBy   = "OpportunityPortal"
  }
}

output "bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "website_endpoint" {
  value = module.s3_bucket.s3_bucket_website_endpoint
}

output "bucket_regional_domain_name" {
  value = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

