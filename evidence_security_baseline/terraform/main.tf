# Evidence: Security Baseline
# Deploys GuardDuty and Security Hub with CIS + FSBP standards.
# Maps to VCL control prefix: EXCOM
#
# NOTE: AWS Config resources are intentionally excluded.
# Control Tower SCPs deny config:PutConfigurationRecorder in CT-enrolled
# accounts. Security Hub standards (CIS, FSBP) cover the same checks.
#
# Partners screenshot: Security Hub dashboard, GuardDuty findings.

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
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  tags                         = local.common_tags
}

# ── Security Hub ─────────────────────────────────────────────────────────────
resource "aws_securityhub_account" "main" {
  enable_default_standards = false
}

# CIS AWS Foundations Benchmark v1.4
resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

# AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "fsbp" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "guardduty_detector_id" { value = aws_guardduty_detector.main.id }
output "securityhub_account_id" { value = aws_securityhub_account.main.id }
output "findings_bucket" { value = aws_s3_bucket.security_findings.id }
