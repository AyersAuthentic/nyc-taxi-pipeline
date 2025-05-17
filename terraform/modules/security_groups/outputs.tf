output "airflow_ec2_sg_id" {
  description = "The ID of the security group for the Airflow EC2 instance."
  value       = aws_security_group.airflow_ec2_sg.id
}
