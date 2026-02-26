# Evidence: Security Baseline
# Deploys GuardDuty, Security Hub, Config Recorder + Rules, and findings S3 bucket.
# Maps to VCL control prefix: EXCOM
#
# Partners screenshot: Security Hub dashboard, GuardDuty findings, Config compliance.

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
    Stack       = "evidence_security_baseline"
    ManagedBy   = "OpportunityPortal"
    Purpose     = "CompetencyEvidence"
  }
}

# ── S3 Bucket for security findings ──────────────────────────────────────────
resource "aws_s3_bucket" "security_findings" {
  bucket        = "${local.name_prefix}-security-findings"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "security_findings" {
  bucket                  = aws_s3_bucket.security_findings.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── GuardDuty ────────────────────────────────────────────────────────────────
resource "aws_guardduty_detector" "main" {
  enable = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  tags = local.common_tags
}

# ── Security Hub ─────────────────────────────────────────────────────────────
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# ── AWS Config ───────────────────────────────────────────────────────────────
resource "aws_config_configuration_recorder" "main" {
  name     = "${local.name_prefix}-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${local.name_prefix}-delivery"
  s3_bucket_name = aws_s3_bucket.security_findings.id
  s3_key_prefix  = "config"
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# Config IAM Role
resource "aws_iam_role" "config_role" {
  name = "${local.name_prefix}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/Config_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "config-s3-delivery"
  role = aws_iam_role.config_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetBucketAcl"]
      Resource = ["${aws_s3_bucket.security_findings.arn}", "${aws_s3_bucket.security_findings.arn}/*"]
    }]
  })
}

# Config Rules
resource "aws_config_config_rule" "root_mfa" {
  name = "${local.name_prefix}-root-account-mfa"
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder.main]
  tags       = local.common_tags
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "${local.name_prefix}-encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  depends_on = [aws_config_configuration_recorder.main]
  tags       = local.common_tags
}

resource "aws_config_config_rule" "s3_bucket_ssl" {
  name = "${local.name_prefix}-s3-bucket-ssl"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
  depends_on = [aws_config_configuration_recorder.main]
  tags       = local.common_tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "guardduty_detector_id" { value = aws_guardduty_detector.main.id }
output "securityhub_account_id" { value = aws_securityhub_account.main.id }
output "config_recorder_name" { value = aws_config_configuration_recorder.main.name }
output "findings_bucket" { value = aws_s3_bucket.security_findings.id }
