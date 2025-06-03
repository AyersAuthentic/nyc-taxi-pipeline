data "archive_file" "nyc_taxi_ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/nyc_taxi_ingestion/package/"
  output_path = "${path.module}/nyc_taxi_ingestion_payload.zip"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/lambda_function.py"
  output_path = "${path.module}/lambda_payload.zip"
}



resource "aws_lambda_function" "nyc_taxi_ingestion_lambda" {
  function_name = "${var.project_name}-nyc-taxi-ingest-${var.environment}"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_execution_role_arn

  environment {
    variables = {
      BRONZE_BUCKET_NAME   = var.bronze_bucket_name
      TLC_DATA_BASE_URL    = var.tlc_data_base_url
      HTTP_REQUEST_TIMEOUT = var.http_request_timeout_seconds
    }
  }

  filename         = data.archive_file.nyc_taxi_ingestion_zip.output_path
  source_code_hash = data.archive_file.nyc_taxi_ingestion_zip.output_base64sha256

  timeout     = var.lambda_timeout_seconds
  memory_size = var.lambda_memory_mb

  tags = merge(var.tags, {
    Name    = "${var.project_name}-nyc-taxi-ingest-${var.environment}",
    Purpose = "Ingest NYC Taxi Data Placeholder"
  })
}


resource "aws_lambda_function" "noaa_weather_ingestion_lambda" {
  function_name = "${var.project_name}-noaa-weather-ingest-${var.environment}"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_execution_role_arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = var.lambda_timeout_seconds
  memory_size = var.lambda_memory_mb

  environment {
    variables = {
      NOAA_API_KEY_SECRET_ARN = var.noaa_api_key_secret_arn
    }
  }


  tags = merge(var.tags, {
    Name    = "${var.project_name}-noaa-weather-ingest-${var.environment}",
    Purpose = "Ingest NOAA Weather Data Placeholder"
  })
}
