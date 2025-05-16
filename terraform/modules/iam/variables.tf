variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default     = {}
}

# --- Variables for Role-Lambda-External ---
variable "bronze_bucket_arn" {
  description = "The ARN of the S3 bronze bucket where ingestion Lambdas will write data. This is required for the S3 policy."
  type        = string
}

variable "secrets_manager_read_access_arns" {
  description = "A list of ARNs of AWS Secrets Manager secrets that the Lambda external role needs read access to (e.g., for API keys)."
  type        = list(string)
  default     = []
}

# --- Variables for Role-Airflow-EC2 ---
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "airflow_dags_s3_bucket_arn" {
  description = "ARN of the S3 bucket where Airflow DAGs are stored."
  type        = string
}

variable "airflow_logs_s3_bucket_arn" {
  description = "ARN of the S3 bucket where Airflow task logs are stored."
  type        = string
}

variable "airflow_secrets_manager_arns" {
  description = "A list of ARNs of AWS Secrets Manager secrets that the Airflow EC2 role needs read access to (e.g., RDS password, API keys)."
  type        = list(string)
  default     = []
}

variable "ingestion_lambda_function_arns" {
  description = "A list of ARNs of ingestion Lambda functions that Airflow can invoke."
  type        = list(string)
  default     = []
}

variable "redshift_serverless_workgroup_arn" {
  description = "ARN of the Redshift Serverless workgroup for Data API access. Required if Airflow needs to query Redshift."
  type        = string
  default     = null
}

variable "redshift_serverless_namespace_arn" {
  description = "ARN of the Redshift Serverless namespace. Often the same as workgroup ARN for some permissions or can be derived."
  type        = string
  default     = null
}

# --- Variables for Role-Redshift-Cluster ---
variable "silver_bucket_arn" {
  description = "The ARN of the S3 silver bucket for Redshift to read from/write to."
  type        = string
}

variable "gold_bucket_arn" {
  description = "The ARN of the S3 gold bucket for Redshift to read from/write to."
  type        = string
}


# --- Variables for Role-GitHub-Actions-Deploy ---
variable "github_org_name" {
  description = "Your GitHub organization name (e.g., 'MyAwesomeOrg')."
  type        = string
}

variable "github_repo_name" {
  description = "Your GitHub repository name (e.g., 'nyc-taxi-pipeline')."
  type        = string
}

variable "github_oidc_provider_url" {
  description = "The URL of the GitHub OIDC provider. Defaults to the standard GitHub Actions OIDC provider URL."
  type        = string
  default     = "token.actions.githubusercontent.com"

}
