# GuardDuty - Enabled at account level (Control Tower may already enable this)
resource "aws_guardduty_detector" "main" {
  enable = true
}

# Security Hub - Enabled at account level
resource "aws_securityhub_account" "main" {}

# S3 bucket for CloudTrail (optional - if you need account-specific trails)
# Control Tower already provides organization-level CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "cloudtrail-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AWSCloudTrailAclCheck"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "s3:GetBucketAcl"
      Resource  = aws_s3_bucket.cloudtrail.arn
      }, {
      Sid       = "AWSCloudTrailWrite"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.cloudtrail.arn}/*"
      Condition = {
        StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
      }
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# CloudTrail is optional - Control Tower already provides organization-level CloudTrail
# Uncomment if you need account-specific CloudTrail logging
#
# resource "aws_cloudtrail" "main" {
#   name                          = "security-trail"
#   s3_bucket_name                = aws_s3_bucket.cloudtrail.id
#   include_global_service_events = true
#   is_multi_region_trail         = true
#   enable_log_file_validation    = true
#   depends_on                    = [aws_s3_bucket_policy.cloudtrail]
# }

# AWS Config is managed by Control Tower - DO NOT create these resources
# Control Tower uses SCPs to prevent config:PutConfigurationRecorder
# These resources will fail with AccessDeniedException

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
