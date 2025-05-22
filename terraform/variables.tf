variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "nyc-taxi-pipeline"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_org_name" {
  description = "GitHub organization name (e.g., 'MyAwesomeOrg')."
  type        = string
  default     = "AyersAuthentic"
}

variable "github_repo_name" {
  description = "GitHub repository name (e.g., 'nyc-taxi-pipeline')."
  type        = string
  default     = "nyc-taxi-pipeline"
}

variable "user_ssh_ip" {
  description = "Local/Remote IP address (CIDR format, e.g., 'x.x.x.x/32') for SSH access. Set via terraform.tfvars."
  type        = string
}

variable "user_airflow_ui_ip" {
  description = "Local/Remote IP address (CIDR format, e.g., 'x.x.x.x/32') for accessing the Airflow UI. Set via terraform.tfvars."
  type        = string
}

variable "user_metabase_ui_ip" {
  description = "Local/Remote IP address (CIDR format, e.g., 'x.x.x.x/32') for accessing the Metabase UI. Set via terraform.tfvars."
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources created by this module."
  type        = map(string)
  default = {
    Project     = "nyc-taxi-pipeline"
    Environment = "dev"
  }
}

# --- EC2 ---
variable "ec2_key_name" {
  description = "Name of the EC2 key pair for SSH access."
  type        = string
  default     = "nyc-taxi-pipeline-key"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for Airflow (e.g., t3.micro, t4g.micro)."
  type        = string
  default     = "t3.micro"
}



