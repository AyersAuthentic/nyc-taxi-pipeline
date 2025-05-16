variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "bronze_bucket_arn" {
  description = "The ARN of the S3 bronze bucket where ingestion Lambdas will write data. This is required for the S3 policy."
  type        = string
}

variable "secrets_manager_read_access_arns" {
  description = "A list of ARNs of AWS Secrets Manager secrets that the Lambda external role needs read access to (e.g., for API keys)."
  type        = list(string)
  default     = []
}
