output "bucket_names" {
  description = "Map of bucket tier ⇒ name"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket }
}

output "bronze_bucket_arn" {
  description = "The ARN of the bronze S3 bucket."
  value       = aws_s3_bucket.this["bronze"].arn
}

output "silver_bucket_arn" {
  description = "The ARN of the silver S3 bucket."
  value       = aws_s3_bucket.this["silver"].arn
}

output "gold_bucket_arn" {
  description = "The ARN of the gold S3 bucket."
  value       = aws_s3_bucket.this["gold"].arn
}

output "airflow_dags_s3_bucket_arn" {
  description = "The ARN of the S3 bucket for storing Airflow DAGs."
  value       = aws_s3_bucket.airflow_dags.arn
}

output "airflow_logs_s3_bucket_arn" {
  description = "The ARN of the S3 bucket for storing Airflow logs."
  value       = aws_s3_bucket.airflow_logs.arn
}


output "bronze_bucket_id" {
  description = "The ID (name) of the bronze S3 bucket."
  value       = aws_s3_bucket.this["bronze"].id
}

output "silver_bucket_id" {
  description = "The ID (name) of the silver S3 bucket."
  value       = aws_s3_bucket.this["silver"].id
}

output "gold_bucket_id" {
  description = "The ID (name) of the gold S3 bucket."
  value       = aws_s3_bucket.this["gold"].id
}
