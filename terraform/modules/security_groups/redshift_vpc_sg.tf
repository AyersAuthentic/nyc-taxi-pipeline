data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

# --- Redshift VPC Security Group (for ENIs) ---
resource "aws_security_group" "redshift_vpc_sg" {
  name        = "${var.project_name}-${var.environment}-redshift-vpc-sg"
  description = "Security group for Redshift Serverless ENIs within the VPC"
  vpc_id      = var.vpc_id


  ingress {
    description = "Direct Redshift access from my admin IP"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.local_ip_for_ssh]
  }

  egress {
    description     = "Allow outbound HTTPS to S3 via S3 Gateway Endpoint"
    from_port       = 443 # HTTPS
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3.id]
  }


  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redshift-vpc-sg"
    }
  )
}

resource "aws_security_group_rule" "redshift_ingress_from_airflow_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.redshift_vpc_sg.id
  source_security_group_id = aws_security_group.airflow_ec2_sg.id
  from_port                = 5439
  to_port                  = 5439
  protocol                 = "tcp"
  description              = "Ingress from Airflow EC2 to Redshift"
}
