# --- RDS Airflow Security Group ---
resource "aws_security_group" "rds_airflow_sg" {
  name        = "${var.project_name}-${var.environment}-rds-airflow-sg"
  description = "Security group for the RDS PostgreSQL instance for Airflow metadata"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from Airflow EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow_ec2_sg.id]
  }



  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-airflow-sg"
    }
  )
}
