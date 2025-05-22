
data "aws_ami" "amazon_linux_2" {
  count = var.ami_id == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "airflow_ec2" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2[0].id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.ec2_key_name

  vpc_security_group_ids = [var.airflow_ec2_sg_id]
  iam_instance_profile   = var.iam_instance_profile_name


  associate_public_ip_address = true


  user_data = var.user_data_script != null ? var.user_data_script : <<-EOF
              #!/bin/bash
              sudo yum update -y
              # Install Docker
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              # Install Docker Compose
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              # Install Git
              sudo yum install git -y
              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              rm -rf awscliv2.zip aws
              # Example: Clone your project (replace with your repo)
              # sudo -u ec2-user git clone https://github.com/your-username/your-airflow-project.git /home/ec2-user/airflow_project
              echo "User data script completed." > /home/ec2-user/user_data_status.txt
              EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-airflow-ec2-${var.environment}"
  })
}

resource "aws_eip" "airflow_eip" {

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-airflow-eip-${var.environment}"
  })
}

resource "aws_eip_association" "airflow_eip_assoc" {
  instance_id   = aws_instance.airflow_ec2.id
  allocation_id = aws_eip.airflow_eip.id
}
