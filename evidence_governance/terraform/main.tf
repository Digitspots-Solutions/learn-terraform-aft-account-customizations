# Evidence: Governance
# Deploys CloudTrail trail with S3 log bucket, Config Aggregator, CloudWatch log group.
# Maps to VCL control prefix: EXCG
#
# Partners screenshot: CloudTrail event history, Config aggregator compliance.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "portal-evidence-${data.aws_caller_identity.current.account_id}"
  common_tags = {
    Environment = var.environment
    Stack       = "evidence_governance"
    ManagedBy   = "OpportunityPortal"
    Purpose     = "CompetencyEvidence"
  }
}

# ── S3 Bucket for CloudTrail logs ────────────────────────────────────────────
resource "aws_s3_bucket" "trail_logs" {
  bucket        = "${local.name_prefix}-trail-logs"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "trail_logs" {
  bucket                  = aws_s3_bucket.trail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "trail_logs" {
  bucket = aws_s3_bucket.trail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# ── CloudWatch Log Group for CloudTrail ──────────────────────────────────────
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${local.name_prefix}-governance"
  retention_in_days = 90
  tags              = local.common_tags
}

resource "aws_iam_role" "cloudtrail_cw" {
  name = "${local.name_prefix}-cloudtrail-cw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_cw" {
  name = "cloudtrail-cloudwatch-logs"
  role = aws_iam_role.cloudtrail_cw.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
    }]
  })
}

# ── CloudTrail ───────────────────────────────────────────────────────────────
resource "aws_cloudtrail" "governance" {
  name                       = "${local.name_prefix}-governance-trail"
  s3_bucket_name             = aws_s3_bucket.trail_logs.id
  include_global_service_events = true
  is_multi_region_trail      = true
  enable_log_file_validation = true
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cw.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.trail_logs]
  tags       = local.common_tags
}

# ── Config Aggregator ────────────────────────────────────────────────────────
resource "aws_config_configuration_aggregator" "governance" {
  name = "${local.name_prefix}-config-aggregator"

  account_aggregation_source {
    account_ids = [data.aws_caller_identity.current.account_id]
    regions     = [data.aws_region.current.name]
  }

  tags = local.common_tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "trail_name" { value = aws_cloudtrail.governance.name }
output "trail_logs_bucket" { value = aws_s3_bucket.trail_logs.id }
output "log_group_name" { value = aws_cloudwatch_log_group.trail.name }
output "config_aggregator" { value = aws_config_configuration_aggregator.governance.name }
