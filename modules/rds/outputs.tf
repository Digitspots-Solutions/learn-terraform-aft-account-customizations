# RDS Module Outputs

output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_identifier
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "RDS instance address (hostname)"
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_instance_name" {
  description = "Database name"
  value       = module.rds.db_instance_name
}

output "db_instance_username" {
  description = "Master username"
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.security_group.security_group_id
}

