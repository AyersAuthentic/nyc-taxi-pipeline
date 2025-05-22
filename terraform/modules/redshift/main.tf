# /modules/redshift_serverless/main.tf
data "aws_secretsmanager_secret_version" "admin_password" {
  secret_id = var.admin_user_password_secret_arn
}

locals {
  admin_password_from_secret = jsondecode(data.aws_secretsmanager_secret_version.admin_password.secret_string)["password"]
}

resource "aws_redshiftserverless_namespace" "default" {
  namespace_name      = "${var.project_name}-${var.namespace_name_suffix}"
  admin_username      = var.admin_username
  admin_user_password = local.admin_password_from_secret
  db_name             = var.db_name
  iam_roles           = [var.redshift_iam_role_arn]

  tags = var.tags
}

resource "aws_redshiftserverless_workgroup" "default" {
  workgroup_name = "${var.project_name}-${var.workgroup_name_suffix}"
  namespace_name = aws_redshiftserverless_namespace.default.namespace_name
  base_capacity  = var.base_capacity

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.redshift_security_group_id]

  publicly_accessible = true

  tags = var.tags
}
