
output "instance_public_ip" {
  description = "The public IP address of the Airflow EC2 instance, for SSH access."

  value = module.ec2_airflow.instance_public_ip
}

output "instance_id" {
  description = "The ID of the Airflow EC2 instance."
  value       = module.ec2_airflow.instance_id
}
