
output "nyc_taxi_ingestion_lambda_arn" {
  description = "ARN of the NYC Taxi Ingestion Lambda function."
  value       = aws_lambda_function.nyc_taxi_ingestion_lambda.arn
}

output "nyc_taxi_ingestion_lambda_name" {
  description = "Name of the NYC Taxi Ingestion Lambda function."
  value       = aws_lambda_function.nyc_taxi_ingestion_lambda.function_name
}

output "noaa_weather_ingestion_lambda_arn" {
  description = "ARN of the NOAA Weather Ingestion Lambda function."
  value       = aws_lambda_function.noaa_weather_ingestion_lambda.arn
}

output "noaa_weather_ingestion_lambda_name" {
  description = "Name of the NOAA Weather Ingestion Lambda function."
  value       = aws_lambda_function.noaa_weather_ingestion_lambda.function_name
}
