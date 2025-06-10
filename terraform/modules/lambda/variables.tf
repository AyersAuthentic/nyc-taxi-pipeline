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

variable "bronze_bucket_name" {
  description = "Name of the S3 bucket for the Bronze layer."
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda function runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Lambda function handler."
  type        = string
  default     = "app.lambda_handler"
}

variable "lambda_timeout_seconds" {
  description = "Timeout for Lambda functions in seconds."
  type        = number
  default     = 300
}

variable "lambda_memory_mb" {
  description = "Memory size for Lambda functions in MB."
  type        = number
  default     = 512
}

variable "http_request_timeout_seconds" {
  description = "Timeout for HTTP requests in seconds."
  type        = number
  default     = 60
}

variable "tlc_data_base_url" {
  description = "Base URL for the TLC data."
  type        = string
  default     = "https://d37ci6vzurychx.cloudfront.net/trip-data"
}

variable "noaa_api_base_url" {
  description = "Base URL for the NOAA API."
  type        = string
  default     = "https://www.ncei.noaa.gov/cdo-web/api/v2"
}

variable "tags" {
  description = "A map of tags to assign to the Lambda functions."
  type        = map(string)
  default     = {}
}
