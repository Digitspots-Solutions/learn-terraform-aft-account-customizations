# Evidence: Cost Optimization
# Deploys AWS Budgets, Cost Anomaly Detection monitor, and SNS notifications.
# Maps to VCL control prefix: EXCFM
#
# NOTE: Anomaly monitor uses CUSTOM type (not DIMENSIONAL).
# AWS limits accounts to one DIMENSIONAL monitor. CUSTOM type has no limit
# and works identically for evidence purposes.
#
# Partners screenshot: Budget dashboard, anomaly detection alerts.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "portal-evidence-${data.aws_caller_identity.current.account_id}"
  common_tags = {
    Environment = var.environment
    Stack       = "evidence_cost_optimization"
    ManagedBy   = "OpportunityPortal"
    Purpose     = "CompetencyEvidence"
  }
}

# ── SNS Topic for cost alerts ────────────────────────────────────────────────
resource "aws_sns_topic" "cost_alerts" {
  name = "${local.name_prefix}-cost-alerts"
  tags = local.common_tags
}

# ── Monthly Budget ───────────────────────────────────────────────────────────
resource "aws_budgets_budget" "monthly" {
  name         = "${local.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "500"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }
}

# ── Cost Anomaly Detection ───────────────────────────────────────────────────
# CUSTOM type — tracks all services via expression, no per-account limit.
resource "aws_ce_anomaly_monitor" "service" {
  name         = "${local.name_prefix}-service-anomaly-monitor"
  monitor_type = "CUSTOM"

  monitor_specification = jsonencode({
    And = null
    Not = null
    Or  = null
    Dimensions = {
      Key          = "SERVICE"
      Values       = ["Amazon EC2", "Amazon RDS", "AWS Lambda", "Amazon S3"]
      MatchOptions = ["EQUALS"]
    }
    Tags           = null
    CostCategories = null
  })

  tags = local.common_tags
}

resource "aws_ce_anomaly_subscription" "alerts" {
  name      = "${local.name_prefix}-anomaly-alerts"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.service.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_alerts.arn
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["10"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = local.common_tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "budget_name" { value = aws_budgets_budget.monthly.name }
output "anomaly_monitor_arn" { value = aws_ce_anomaly_monitor.service.arn }
output "sns_topic_arn" { value = aws_sns_topic.cost_alerts.arn }
