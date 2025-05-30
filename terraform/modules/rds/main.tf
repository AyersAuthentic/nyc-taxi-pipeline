resource "aws_db_subnet_group" "default" {
  name        = "${var.project_name}-${var.environment}-rds-sng"
  description = "DB Subnet Group for ${var.project_name} ${var.environment}"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-sng"
    }
  )
}

resource "aws_db_instance" "default" {
  identifier             = "${var.project_name}-${var.environment}-airflow-db"
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [var.rds_allowed_sg_id]

  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = var.apply_immediately

  publicly_accessible = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-airflow-db"
    }
  )
}
