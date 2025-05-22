resource "aws_secretsmanager_secret" "rds_master_password" {
  name        = "${var.project_name}-${var.environment}-rds-master-password"
  description = "Stores the master password for the RDS PostgreSQL instance for Airflow."

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-rds-master-password"
      SecretPurpose = "RDS Master Password"
    }
  )
}

resource "aws_secretsmanager_secret" "noaa_api_key" {
  name        = "${var.project_name}-${var.environment}-noaa-api-key"
  description = "Stores the API key for accessing the NOAA CDO v2 API."

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-noaa-api-key"
      SecretPurpose = "NOAA API Key"
    }
  )
}

resource "aws_secretsmanager_secret" "redshift_admin_password" {
  name        = "${var.project_name}-${var.environment}-redshift-admin-password"
  description = "Admin password for Redshift Serverless"

  tags = merge(
    var.tags,
    {
      Name          = "${var.project_name}-${var.environment}-redshift-admin-password"
      SecretPurpose = "Redshift Admin Password"
    }
  )
}
