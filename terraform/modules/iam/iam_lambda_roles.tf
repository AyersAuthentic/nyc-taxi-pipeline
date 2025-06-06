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

data "aws_iam_policy_document" "lambda_s3_nyc_tlc_read_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::nyc-tlc/*"]
  }

}

resource "aws_iam_policy" "lambda_s3_nyc_tlc_read_policy" {
  name        = "LambdaS3NycTlcReadPolicy"
  description = "Allows Lambda functions to read data from the public NYC TLC S3 bucket."
  policy      = data.aws_iam_policy_document.lambda_s3_nyc_tlc_read_policy_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_s3_nyc_tlc_read_attach" {
  role       = aws_iam_role.lambda_external_role.name
  policy_arn = aws_iam_policy.lambda_s3_nyc_tlc_read_policy.arn
}




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


locals {
  enable_secrets_manager_access = length(var.lambda_external_role_secret_arns) > 0
}

data "aws_iam_policy_document" "lambda_external_secrets_manager_policy_doc" {
  count = local.enable_secrets_manager_access ? 1 : 0

  statement {
    sid    = "AllowReadSpecifiedSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.lambda_external_role_secret_arns
  }
}

resource "aws_iam_policy" "lambda_external_secrets_manager_policy" {
  count = local.enable_secrets_manager_access ? 1 : 0

  name        = "LambdaExternalSecretsManagerPolicy"
  description = "Allows Lambda functions to read specified secrets from Secrets Manager."
  policy      = data.aws_iam_policy_document.lambda_external_secrets_manager_policy_doc[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_external_secrets_manager_attach" {
  count = local.enable_secrets_manager_access ? 1 : 0

  role       = aws_iam_role.lambda_external_role.name
  policy_arn = aws_iam_policy.lambda_external_secrets_manager_policy[0].arn
}

