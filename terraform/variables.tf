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
  description = "Your GitHub organization name (e.g., 'MyAwesomeOrg')."
  type        = string
  default     = "AyersAuthentic"
}

variable "github_repo_name" {
  description = "Your GitHub repository name (e.g., 'nyc-taxi-pipeline')."
  type        = string
  default     = "nyc-taxi-pipeline"
}




