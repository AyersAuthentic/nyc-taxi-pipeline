output "lambda_external_role_arn" {
  description = "The ARN of the IAM role for external Lambda functions."
  value       = aws_iam_role.lambda_external_role.arn
}

output "airflow_ec2_role_arn" {
  description = "The ARN of the IAM role for the Airflow EC2 instance."
  value       = aws_iam_role.airflow_ec2_role.arn
}

output "airflow_ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for the Airflow EC2 instance."
  value       = aws_iam_instance_profile.airflow_ec2_instance_profile.name
}
