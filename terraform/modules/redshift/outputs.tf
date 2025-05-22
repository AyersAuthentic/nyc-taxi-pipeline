output "namespace_arn" {
  description = "ARN of the Redshift Serverless namespace."
  value       = aws_redshiftserverless_namespace.default.arn
}

output "namespace_name" {
  description = "Name of the Redshift Serverless namespace."
  value       = aws_redshiftserverless_namespace.default.namespace_name
}

output "workgroup_arn" {
  description = "ARN of the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.default.arn
}

output "workgroup_name" {
  description = "Name of the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.default.workgroup_name
}

output "workgroup_endpoint_address" {
  description = "Endpoint address for the Redshift Serverless workgroup. Excludes port."
  value       = aws_redshiftserverless_workgroup.default.endpoint[0].address
}

output "workgroup_endpoint_port" {
  description = "Endpoint port for the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.default.endpoint[0].port
}

output "workgroup_id" {
  description = "ID of the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.default.workgroup_id
}
