# SQS Module Outputs

output "queue_id" {
  description = "SQS queue ID"
  value       = module.sqs.queue_id
}

output "queue_arn" {
  description = "SQS queue ARN"
  value       = module.sqs.queue_arn
}

output "queue_url" {
  description = "SQS queue URL"
  value       = module.sqs.queue_url
}

output "queue_name" {
  description = "SQS queue name"
  value       = module.sqs.queue_name
}

output "dlq_id" {
  description = "Dead letter queue ID"
  value       = var.create_dlq ? module.dlq[0].queue_id : null
}

output "dlq_arn" {
  description = "Dead letter queue ARN"
  value       = var.create_dlq ? module.dlq[0].queue_arn : null
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = var.create_dlq ? module.dlq[0].queue_url : null
}

