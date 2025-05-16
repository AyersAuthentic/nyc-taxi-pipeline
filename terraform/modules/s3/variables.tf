variable "bucket_prefix" {
  description = "Base name for all data‑lake buckets"
  type        = string
  default     = "nyc-taxi-pipeline"
}

variable "aws_region" {
  description = "AWS region—for endpoint & tagging consistency"
  type        = string
}

variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
