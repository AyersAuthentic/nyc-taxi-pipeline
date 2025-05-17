# --- Variables for Security Groups ---
variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created."
  type        = string
}

variable "project_name" {
  description = "The name of the project (e.g., 'nyc-taxi-pipeline'). Used for naming resources."
  type        = string
}

variable "environment" {
  description = "The name of the environment (e.g., 'dev', 'staging', 'prod'). Used for naming resources."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
}


variable "tags" {
  description = "A map of common tags to apply to all security groups."
  type        = map(string)
  default     = {}
}

variable "local_ip_for_ssh" {
  description = "Your IP address (CIDR format, e.g., 'x.x.x.x/32') for SSH access to EC2 instances. Set to '0.0.0.0/0' for open access (not recommended for SSH)."
  type        = string
}

variable "local_ip_for_airflow_ui" {
  description = "Your IP address (CIDR format, e.g., 'x.x.x.x/32') for accessing the Airflow UI. Set to '0.0.0.0/0' for public access (ensure Airflow itself is secured)."
  type        = string
}

variable "local_ip_for_metabase_ui" {
  description = "Your IP address (CIDR format, e.g., 'x.x.x.x/32') for accessing the Metabase UI. Set to '0.0.0.0/0' for public access (ensure Metabase itself is secured)."
  type        = string
}
