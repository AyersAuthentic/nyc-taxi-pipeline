variable "project_name" {
  description = "A name for the project, used for prefixing/naming resources."
  type        = string
}

variable "namespace_name_suffix" {
  description = "Suffix for the Redshift Serverless namespace name (project_name will be prefixed)."
  type        = string
  default     = "redshift-ns"
}

variable "admin_username" {
  description = "Admin username for the Redshift Serverless namespace."
  type        = string
  default     = "adminuser"
}

variable "admin_user_password_secret_arn" {
  description = "ARN of the secret in AWS Secrets Manager for the admin password."
  type        = string
}

variable "db_name" {
  description = "Default database name in the Redshift Serverless namespace."
  type        = string
  default     = "dev"
}

variable "redshift_iam_role_arn" {
  description = "ARN of the IAM role for Redshift Serverless to interact with other AWS services (e.g., S3)."
  type        = string

}

variable "workgroup_name_suffix" {
  description = "Suffix for the Redshift Serverless workgroup name (project_name will be prefixed)."
  type        = string
  default     = "redshift-wg"
}

variable "base_capacity" {
  description = "The base Redshift Processing Units (RPU) for the workgroup. Min is 8 for cost saving."
  type        = number
  default     = 8
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Redshift workgroup ENIs."
  type        = list(string)
}

variable "redshift_security_group_id" {
  description = "ID of the security group for Redshift Serverless (SG_Redshift_VPC)."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
