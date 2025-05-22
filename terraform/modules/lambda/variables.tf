# /modules/lambda_functions/variables.tf

variable "project_name" {
  description = "A name for the project, used for naming Lambda functions."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_execution_role_arn" {
  description = "ARN of the IAM role for Lambda functions (Role_Lambda_External)."
  type        = string
}

variable "noaa_api_key_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the NOAA API key."
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda function runtime."
  type        = string
  default     = "python3.9"
}

variable "lambda_handler" {
  description = "Lambda function handler."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_timeout_seconds" {
  description = "Timeout for Lambda functions in seconds."
  type        = number
  default     = 60
}

variable "lambda_memory_mb" {
  description = "Memory size for Lambda functions in MB."
  type        = number
  default     = 128
}

variable "tags" {
  description = "A map of tags to assign to the Lambda functions."
  type        = map(string)
  default     = {}
}
