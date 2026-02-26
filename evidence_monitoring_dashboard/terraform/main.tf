# Evidence: Monitoring Dashboard
# Deploys CloudWatch dashboards, metric alarms, and SNS notification topic.
# Maps to VCL control prefix: EXAMO
#
# Partners screenshot: CloudWatch dashboard with widgets, alarm history.

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
    Stack       = "evidence_monitoring_dashboard"
    ManagedBy   = "OpportunityPortal"
    Purpose     = "CompetencyEvidence"
  }
}

# ── SNS Topic for alarm notifications ────────────────────────────────────────
resource "aws_sns_topic" "monitoring_alerts" {
  name = "${local.name_prefix}-monitoring-alerts"
  tags = local.common_tags
}

# ── CloudWatch Dashboard ─────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${local.name_prefix}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0, y = 0, width = 24, height = 2
        properties = {
          markdown = "# Operations Monitoring Dashboard\n**Account:** ${data.aws_caller_identity.current.account_id} | **Region:** ${data.aws_region.current.name} | Managed by OpportunityPortal"
        }
      },
      {
        type   = "metric"
        x      = 0, y = 2, width = 12, height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12, y = 2, width = 12, height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", period = 300 }],
            ["AWS/RDS", "FreeableMemory", { stat = "Average", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "RDS Performance"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0, y = 8, width = 12, height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", period = 300 }],
            ["AWS/Lambda", "Errors", { stat = "Sum", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Lambda Invocations & Errors"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12, y = 8, width = 12, height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", period = 300 }],
            ["AWS/ECS", "MemoryUtilization", { stat = "Average", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ECS Resource Utilization"
          period  = 300
        }
      }
    ]
  })
}

# ── CloudWatch Alarms ────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeds 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda error count exceeds 5 in 5 minutes"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.common_tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "dashboard_name" { value = aws_cloudwatch_dashboard.operations.dashboard_name }
output "sns_topic_arn" { value = aws_sns_topic.monitoring_alerts.arn }
output "high_cpu_alarm" { value = aws_cloudwatch_metric_alarm.high_cpu.alarm_name }
