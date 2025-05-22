output "instance_id" {
  description = "ID of the Airflow EC2 instance."
  value       = aws_instance.airflow_ec2.id
}

output "instance_public_ip" {
  description = "Public IP address assigned to the Airflow EC2 instance via EIP."
  value       = aws_eip.airflow_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the Airflow EC2 instance."
  value       = aws_instance.airflow_ec2.private_ip
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP."
  value       = aws_eip.airflow_eip.id
}
