variable "project_name" {
  description = "A name for the project, used for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for Airflow (e.g., t3.micro, t4g.micro)."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Specific AMI ID to use. If not provided, latest Amazon Linux 2 will be used."
  type        = string
  default     = ""
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the Airflow EC2 instance will be launched."
  type        = string
}

variable "airflow_ec2_sg_id" {
  description = "ID of the Security Group for the Airflow EC2 instance (SG_Airflow_EC2)."
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for the Airflow EC2 instance (Role-Airflow-EC2)."
  type        = string
}

variable "ec2_key_name" {
  description = "Name of the EC2 key pair for SSH access."
  type        = string
}

variable "user_data_script" {
  description = "User data script to run on instance launch. Can be a string or use file() function."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the EC2 instance and EIP."
  type        = map(string)
  default     = {}
}
