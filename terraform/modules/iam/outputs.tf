output "lambda_external_role_arn" {
  description = "The ARN of the IAM role for external Lambda functions."
  value       = aws_iam_role.lambda_external_role.arn
}
