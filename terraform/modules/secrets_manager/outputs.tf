output "rds_master_password_secret_arn" {
  description = "The ARN of the RDS master password secret in Secrets Manager."
  value       = aws_secretsmanager_secret.rds_master_password.arn
}

output "noaa_api_key_secret_arn" {
  description = "The ARN of the NOAA API key secret in Secrets Manager."
  value       = aws_secretsmanager_secret.noaa_api_key.arn
}

output "rds_master_password_secret_name" {
  description = "The name of the RDS master password secret in Secrets Manager."
  value       = aws_secretsmanager_secret.rds_master_password.name
}

output "noaa_api_key_secret_name" {
  description = "The name of the NOAA API key secret in Secrets Manager."
  value       = aws_secretsmanager_secret.noaa_api_key.name
}
