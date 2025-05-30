resource "random_password" "rds_password" {
  length           = 20
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?_~"
}


resource "aws_secretsmanager_secret" "rds_master_password" {
  name                    = "${var.project_name}-${var.environment}-rds-master-password"
  description             = "Stores the master password for the RDS PostgreSQL instance for Airflow."
  recovery_window_in_days = 0

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-rds-master-password"
      SecretPurpose = "RDS Master Password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_master_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = random_password.rds_password.result
}


resource "aws_secretsmanager_secret" "noaa_api_key" {
  name                    = "${var.project_name}-${var.environment}-noaa-api-key"
  description             = "Stores the API key for accessing the NOAA CDO v2 API."
  recovery_window_in_days = 0

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-noaa-api-key"
      SecretPurpose = "NOAA API Key"
    }
  )
}


resource "random_password" "redshift_password" {
  length           = 20
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?_~"
}

resource "aws_secretsmanager_secret" "redshift_admin_password" {
  name                    = "${var.project_name}-${var.environment}-redshift-admin-password"
  description             = "Admin password for Redshift Serverless"
  recovery_window_in_days = 0

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-redshift-admin-password"
      SecretPurpose = "Redshift Admin Password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redshift_admin_password_version" {
  secret_id     = aws_secretsmanager_secret.redshift_admin_password.id
  secret_string = random_password.redshift_password.result
}
