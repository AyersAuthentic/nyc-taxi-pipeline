output "bucket_names" {
  description = "Map of bucket tier ⇒ name"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket }
}
