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

output "redshift_serverless_role_arn" {
  description = "The ARN of the IAM role for Redshift Serverless to access other AWS services (e.g., S3)."
  value       = aws_iam_role.redshift_serverless_role.arn
}

output "github_actions_deploy_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to deploy project resources via Terraform."
  value       = aws_iam_role.github_actions_deploy_role.arn
}
