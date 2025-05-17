# --- Metabase EC2 Security Group ---
resource "aws_security_group" "metabase_ec2_sg" {
  name        = "${var.project_name}-${var.environment}-metabase-ec2-sg"
  description = "Security group for the Metabase EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip_for_ssh]
  }

  ingress {
    description = "Metabase UI access from my IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = []
  }

  egress {
    description = "Allow outbound HTTPS to anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow outbound to Redshift"
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    security_groups = []
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-metabase-ec2-sg"
    }
  )
}
