resource "aws_security_group" "airflow_ec2_sg" {
  name        = "${var.project_name}-sg-airflow-ec2-${var.environment}"
  description = "Security group for the Airflow EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-sg-airflow-ec2-${var.environment}"
  })


  ingress {
    description = "Allow SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip_for_ssh]
  }

  ingress {
    description = "Allow Airflow UI from My IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.local_ip_for_airflow_ui]
  }


  egress {
    description = "Allow all outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # TODO (to be refined when other SGs are defined):
  # - Egress to SG_RDS_Airflow on port 5432 (PostgreSQL)
  # - Egress to SG_Redshift_VPC on port 5439 (Redshift)
}
