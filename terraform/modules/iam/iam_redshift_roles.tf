# -----------------------------------------------------------------------------
# IAM Role for Redshift Serverless (Role-Redshift-Cluster)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "redshift_serverless_role" {
  name = "${var.project_name}-Role-Redshift-Serverless-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-Role-Redshift-Serverless-${var.environment}"
    Description = "IAM Role for Redshift Serverless to access other AWS services (e.g., S3)."
  })
}

# --- S3 Access Policy for Redshift Serverless ---
data "aws_iam_policy_document" "redshift_serverless_s3_access_policy_doc" {
  # Permissions for COPY from Bronze & Silver
  statement {
    sid    = "AllowRedshiftCOPY"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      var.bronze_bucket_arn,
      "${var.bronze_bucket_arn}/*",
      var.silver_bucket_arn,
      "${var.silver_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "AllowRedshiftUNLOAD"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.silver_bucket_arn,
      "${var.silver_bucket_arn}/*",
      var.gold_bucket_arn,
      "${var.gold_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "redshift_serverless_s3_access_policy" {
  name        = "${var.project_name}-RedshiftServerlessS3AccessPolicy-${var.environment}"
  description = "Allows Redshift Serverless to access S3 for COPY and UNLOAD operations."
  policy      = data.aws_iam_policy_document.redshift_serverless_s3_access_policy_doc.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "redshift_serverless_s3_access_attach" {
  role       = aws_iam_role.redshift_serverless_role.name
  policy_arn = aws_iam_policy.redshift_serverless_s3_access_policy.arn
}
