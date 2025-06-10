# -----------------------------------------------------------------------------
# IAM Role for Airflow EC2 Instance (Role-Airflow-EC2)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "airflow_ec2_role" {
  name = "${var.project_name}-Role-Airflow-EC2-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-Role-Airflow-EC2-${var.environment}"
    Description = "IAM Role for the Airflow EC2 instance"
  })
}

# --- Instance Profile for Airflow EC2 Role ---
resource "aws_iam_instance_profile" "airflow_ec2_instance_profile" {
  name = "${var.project_name}-InstanceProfile-Airflow-EC2-${var.environment}"
  role = aws_iam_role.airflow_ec2_role.name
  tags = var.tags
}

# --- SSM Managed Policy Attachment for Airflow EC2 Role ---
resource "aws_iam_role_policy_attachment" "airflow_ec2_ssm_core_attach" {
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- S3 Access Policy for Airflow (DAGs and Logs) ---
data "aws_iam_policy_document" "airflow_ec2_s3_policy_doc" {
  statement {
    sid    = "AllowAirflowDAGsAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket"
    ]
    resources = [
      var.airflow_dags_s3_bucket_arn,
      "${var.airflow_dags_s3_bucket_arn}/*"
    ]
  }
  statement {
    sid    = "AllowAirflowLogsAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.airflow_logs_s3_bucket_arn,
      "${var.airflow_logs_s3_bucket_arn}/*"
    ]
  }
}
resource "aws_iam_policy" "airflow_ec2_s3_policy" {
  name        = "${var.project_name}-AirflowEC2S3Policy-${var.environment}"
  description = "Allows Airflow EC2 to access S3 for DAGs and Logs."
  policy      = data.aws_iam_policy_document.airflow_ec2_s3_policy_doc.json
  tags        = var.tags
}
resource "aws_iam_role_policy_attachment" "airflow_ec2_s3_attach" {
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_s3_policy.arn
}

# --- CloudWatch Logs Policy for Airflow EC2 ---
data "aws_iam_policy_document" "airflow_ec2_cloudwatch_policy_doc" {
  statement {
    sid    = "AllowAirflowEC2Logging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = ["arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/${var.project_name}/${var.environment}/ec2/airflow*:*"]
  }
}
resource "aws_iam_policy" "airflow_ec2_cloudwatch_policy" {
  name        = "${var.project_name}-AirflowEC2CloudWatchPolicy-${var.environment}"
  description = "Allows Airflow EC2 to write to CloudWatch Logs."
  policy      = data.aws_iam_policy_document.airflow_ec2_cloudwatch_policy_doc.json
  tags        = var.tags
}
resource "aws_iam_role_policy_attachment" "airflow_ec2_cloudwatch_attach" {
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_cloudwatch_policy.arn
}

# --- Secrets Manager Policy for Airflow EC2 (Conditional) ---
locals {
  enable_airflow_secrets_manager_access = length(var.airflow_ec2_role_secret_arns) > 0
}
data "aws_iam_policy_document" "airflow_ec2_secrets_manager_policy_doc" {
  count = local.enable_airflow_secrets_manager_access ? 1 : 0
  statement {
    sid       = "AllowReadSpecifiedSecretsForAirflow"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.airflow_ec2_role_secret_arns
  }
}
resource "aws_iam_policy" "airflow_ec2_secrets_manager_policy" {
  count       = local.enable_airflow_secrets_manager_access ? 1 : 0
  name        = "${var.project_name}-AirflowEC2SecretsManagerPolicy-${var.environment}"
  description = "Allows Airflow EC2 to read specified secrets."
  policy      = data.aws_iam_policy_document.airflow_ec2_secrets_manager_policy_doc[0].json
  tags        = var.tags
}
resource "aws_iam_role_policy_attachment" "airflow_ec2_secrets_manager_attach" {
  count      = local.enable_airflow_secrets_manager_access ? 1 : 0
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_secrets_manager_policy[0].arn
}


# --- RDS Describe Policy for Airflow EC2 ---
data "aws_iam_policy_document" "airflow_ec2_rds_describe_policy_doc" {
  statement {
    sid    = "AllowRDSDescribe"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "airflow_ec2_rds_describe_policy" {
  name        = "${var.project_name}-AirflowEC2RDSDescribePolicy-${var.environment}"
  description = "Allows Airflow EC2 to describe RDS instances to find the endpoint."
  policy      = data.aws_iam_policy_document.airflow_ec2_rds_describe_policy_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "airflow_ec2_rds_describe_attach" {
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_rds_describe_policy.arn
}

# --- Lambda Invoke Policy for Airflow EC2 (Conditional) ---
locals {
  enable_airflow_lambda_invoke = length(var.ingestion_lambda_function_arns) > 0
}
data "aws_iam_policy_document" "airflow_ec2_lambda_invoke_policy_doc" {
  count = local.enable_airflow_lambda_invoke ? 1 : 0
  statement {
    sid       = "AllowInvokeIngestionLambdas"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = var.ingestion_lambda_function_arns
  }
}
resource "aws_iam_policy" "airflow_ec2_lambda_invoke_policy" {
  count       = local.enable_airflow_lambda_invoke ? 1 : 0
  name        = "${var.project_name}-AirflowEC2LambdaInvokePolicy-${var.environment}"
  description = "Allows Airflow EC2 to invoke specified Lambda functions."
  policy      = data.aws_iam_policy_document.airflow_ec2_lambda_invoke_policy_doc[0].json
  tags        = var.tags
}
resource "aws_iam_role_policy_attachment" "airflow_ec2_lambda_invoke_attach" {
  count      = local.enable_airflow_lambda_invoke ? 1 : 0
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_lambda_invoke_policy[0].arn
}

# --- Redshift Access Policy for Airflow EC2 (Conditional for Data API) ---
locals {
  enable_airflow_redshift_data_api_access = var.redshift_serverless_workgroup_arn != null # Simplified condition
}
data "aws_iam_policy_document" "airflow_ec2_redshift_policy_doc" {
  count = local.enable_airflow_redshift_data_api_access ? 1 : 0
  statement {
    sid    = "AllowRedshiftDataAPI"
    effect = "Allow"
    actions = [
      "redshift-data:ExecuteStatement",
      "redshift-data:DescribeStatement",
      "redshift-data:GetStatementResult",
      "redshift-data:CancelStatement",
      "redshift-data:ListStatements"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "airflow_ec2_redshift_policy" {
  count       = local.enable_airflow_redshift_data_api_access ? 1 : 0
  name        = "${var.project_name}-AirflowEC2RedshiftPolicy-${var.environment}"
  description = "Allows Airflow EC2 to query Redshift via Data API."
  policy      = data.aws_iam_policy_document.airflow_ec2_redshift_policy_doc[0].json
  tags        = var.tags
}
resource "aws_iam_role_policy_attachment" "airflow_ec2_redshift_attach" {
  count      = local.enable_airflow_redshift_data_api_access ? 1 : 0
  role       = aws_iam_role.airflow_ec2_role.name
  policy_arn = aws_iam_policy.airflow_ec2_redshift_policy[0].arn
}
