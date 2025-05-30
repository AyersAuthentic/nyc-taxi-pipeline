output "db_instance_address" {
  description = "The address of the RDS instance."
  value       = aws_db_instance.default.address
}

output "db_instance_port" {
  description = "The port on which the DB instance is listening."
  value       = aws_db_instance.default.port
}

output "db_instance_name" {
  description = "The database name (the one specified as var.db_name)."
  value       = aws_db_instance.default.db_name
}

output "db_instance_username" {
  description = "The master username for the database."
  value       = aws_db_instance.default.username
}

output "db_instance_id" {
  description = "The ID of the RDS instance."
  value       = aws_db_instance.default.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.default.arn
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group."
  value       = aws_db_subnet_group.default.name
}

