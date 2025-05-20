variable "project_name" {
  description = "The name of the project, used for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, prod), used for tagging and naming resources."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "rds_allowed_sg_id" {
  description = "The ID of the security group that is allowed to connect to this RDS instance (e.g., Airflow EC2 SG)."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "The storage type for the RDS instance (e.g., gp3, gp2, io1)."
  type        = string
  default     = "gp3"
}

variable "db_engine" {
  description = "The database engine to use."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "The database engine version."
  type        = string
  default     = "15.10"
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created."
  type        = string
  default     = "airflow_metadata"
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  default     = "airflow_user"
}

variable "db_password_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding the master DB password."
  type        = string
}

variable "rds_backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 7
}

variable "rds_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
  type        = bool
  default     = true
}
