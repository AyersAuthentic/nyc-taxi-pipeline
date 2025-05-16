resource "aws_iam_role" "lambda_external_role" {
  name = "Role-Lambda-External"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "Role-Lambda-External"
    Description = "IAM Role for external data ingestion Lambda functions"
  })
}

# --- Permissions Policy for CloudWatch Logs ---

data "aws_iam_policy_document" "lambda_external_cloudwatch_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_external_cloudwatch_policy" {
  name        = "LambdaExternalCloudWatchPolicy"
  description = "Allows Lambda functions to write to CloudWatch Logs."
  policy      = data.aws_iam_policy_document.lambda_external_cloudwatch_policy_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_external_cloudwatch_attach" {
  role       = aws_iam_role.lambda_external_role.name
  policy_arn = aws_iam_policy.lambda_external_cloudwatch_policy.arn
}

# --- Permissions Policy for S3 Bronze Bucket Access ---

data "aws_iam_policy_document" "lambda_external_s3_bronze_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      var.bronze_bucket_arn,
      "${var.bronze_bucket_arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.bronze_bucket_arn]
  }
}

resource "aws_iam_policy" "lambda_external_s3_bronze_policy" {
  name        = "LambdaExternalS3BronzePolicy"
  description = "Allows Lambda functions to write to the S3 bronze bucket."
  policy      = data.aws_iam_policy_document.lambda_external_s3_bronze_policy_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_external_s3_bronze_attach" {
  role       = aws_iam_role.lambda_external_role.name
  policy_arn = aws_iam_policy.lambda_external_s3_bronze_policy.arn
}

# Permissions Policy for Secrets Manager Access (Conditional)
locals {
  # Determine if Secrets Manager access is requested by checking if the input list has items.
  enable_secrets_manager_access = length(var.secrets_manager_read_access_arns) > 0
}

data "aws_iam_policy_document" "lambda_external_secrets_manager_policy_doc" {
  # Only process this data source if enable_secrets_manager_access is true.
  count = local.enable_secrets_manager_access ? 1 : 0

  statement {
    sid    = "AllowReadSpecifiedSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
      # "secretsmanager:DescribeSecret" # Optional, if Lambda needs to check if a secret exists first
    ]
    # Grants read access ONLY to the specific secret ARNs passed in var.secrets_manager_read_access_arns.
    resources = var.secrets_manager_read_access_arns
  }
}

resource "aws_iam_policy" "lambda_external_secrets_manager_policy" {
  # Only create this policy if enable_secrets_manager_access is true.
  count = local.enable_secrets_manager_access ? 1 : 0

  # Consider parameterizing the name.
  name        = "LambdaExternalSecretsManagerPolicy"
  description = "Allows Lambda functions to read specified secrets from Secrets Manager."
  # Access the policy document using the count index [0] because 'count' makes it a list.
  policy = data.aws_iam_policy_document.lambda_external_secrets_manager_policy_doc[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_external_secrets_manager_attach" {
  # Only create this attachment if enable_secrets_manager_access is true.
  count = local.enable_secrets_manager_access ? 1 : 0

  role = aws_iam_role.lambda_external_role.name
  # Access the policy ARN using the count index [0].
  policy_arn = aws_iam_policy.lambda_external_secrets_manager_policy[0].arn
}

