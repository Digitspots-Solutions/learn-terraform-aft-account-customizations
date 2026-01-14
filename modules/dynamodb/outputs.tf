# DynamoDB Module Outputs

output "table_id" {
  description = "DynamoDB table ID"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb_table.dynamodb_table_arn
}

output "table_name" {
  description = "DynamoDB table name"
  value       = local.table_name
}

output "table_stream_arn" {
  description = "DynamoDB table stream ARN"
  value       = var.enable_stream ? module.dynamodb_table.dynamodb_table_stream_arn : null
}

output "table_stream_label" {
  description = "DynamoDB table stream label"
  value       = var.enable_stream ? module.dynamodb_table.dynamodb_table_stream_label : null
}

