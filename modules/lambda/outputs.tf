# Lambda Module Outputs

output "function_name" {
  description = "Lambda function name"
  value       = module.lambda.lambda_function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.lambda_function_arn
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = module.lambda.lambda_function_invoke_arn
}

output "function_url" {
  description = "Lambda function URL (if enabled)"
  value       = try(module.lambda.lambda_function_url, null)
}

output "role_arn" {
  description = "IAM role ARN"
  value       = module.lambda.lambda_role_arn
}

output "role_name" {
  description = "IAM role name"
  value       = module.lambda.lambda_role_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name"
  value       = module.lambda.lambda_cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = module.lambda.lambda_cloudwatch_log_group_arn
}

output "api_endpoint" {
  description = "API Gateway endpoint (if created)"
  value       = var.create_api_gateway ? module.api_gateway[0].api_endpoint : null
}

output "api_id" {
  description = "API Gateway ID (if created)"
  value       = var.create_api_gateway ? module.api_gateway[0].api_id : null
}

