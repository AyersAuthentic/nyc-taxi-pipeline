output "airflow_ec2_sg_id" {
  description = "The ID of the security group for the Airflow EC2 instance."
  value       = aws_security_group.airflow_ec2_sg.id
}

output "metabase_ec2_sg_id" {
  description = "The ID of the Metabase EC2 security group."
  value       = aws_security_group.metabase_ec2_sg.id
}

output "rds_airflow_sg_id" {
  description = "The ID of the RDS Airflow security group."
  value       = aws_security_group.rds_airflow_sg.id
}
