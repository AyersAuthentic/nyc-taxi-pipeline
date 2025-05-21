# --- RDS Airflow Security Group ---
resource "aws_security_group" "rds_airflow_sg" {
  name        = "${var.project_name}-${var.environment}-rds-airflow-sg"
  description = "Security group for the RDS PostgreSQL instance for Airflow metadata"
  vpc_id      = var.vpc_id


  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-airflow-sg"
    }
  )
}

resource "aws_security_group_rule" "rds_ingress_from_airflow_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_airflow_sg.id
  source_security_group_id = aws_security_group.airflow_ec2_sg.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  description              = "Ingress from Airflow EC2 to RDS (PostgreSQL)"
}
