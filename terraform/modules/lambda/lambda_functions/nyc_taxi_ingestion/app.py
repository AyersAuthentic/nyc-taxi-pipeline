import json
import logging
import os

import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")


TLC_DATA_BASE_URL = os.getenv(
    "TLC_DATA_BASE_URL", "https://d37ci6vzurychx.cloudfront.net/trip-data"
)
HTTP_REQUEST_TIMEOUT = int(os.getenv("HTTP_REQUEST_TIMEOUT", "60"))


def lambda_handler(event, context):
    """
    Downloads a specific NYC Taxi Parquet file from its public CloudFront URL
    using streaming and uploads it to the project's S3 Bronze bucket.

    Expected event keys:
        - 'year': str, the year of the taxi data (e.g., "2024")
        - 'month': str, the month of the taxi data (e.g., "01")
        - 'taxi_type': str, 'yellow' or 'green' (or fhv, hvfhv if you use them)
    """
    try:
        log_message_event = f"AWS Request ID: {context.aws_request_id} - Received event: {event}"
        logger.info(log_message_event)

        year = event.get("year")
        month = event.get("month")
        taxi_type = event.get("taxi_type")

        if not all([year, month, taxi_type]):
            error_msg = "Missing required parameters: 'year', 'month', or 'taxi_type'."
            logger.error(error_msg)
            return {"statusCode": 400, "body": json.dumps({"error": error_msg})}

        month = month.zfill(2)

        bronze_bucket_name = os.environ.get("BRONZE_BUCKET_NAME")
        if not bronze_bucket_name:
            error_msg = "Environment variable BRONZE_BUCKET_NAME not set."
            logger.error(error_msg)
            return {"statusCode": 500, "body": json.dumps({"error": error_msg})}

        source_file_name = f"{taxi_type}_tripdata_{year}-{month}.parquet"
        source_url = f"{TLC_DATA_BASE_URL}/{source_file_name}"

        destination_s3_key = (
            f"nyc-taxi/trip_type={taxi_type}/year={year}/month={month}/" f"{source_file_name}"
        )
        log_attempt_message = (
            f"Attempting to download from {source_url} and upload to "
            f"s3://{bronze_bucket_name}/{destination_s3_key}"
        )
        logger.info(log_attempt_message)

        with requests.get(source_url, stream=True, timeout=HTTP_REQUEST_TIMEOUT) as resp:
            resp.raise_for_status()

            s3_client.upload_fileobj(resp.raw, bronze_bucket_name, destination_s3_key)

        success_msg_part1 = f"Successfully downloaded {source_file_name} from {source_url} and "
        success_msg_part2 = f"uploaded to s3://{bronze_bucket_name}/{destination_s3_key}"
        success_msg = success_msg_part1 + success_msg_part2
        logger.info(success_msg)
        return {
            "statusCode": 200,
            "message": success_msg,
            "destination_key": destination_s3_key,
        }

    except requests.exceptions.HTTPError as http_err:
        error_code = http_err.response.status_code
        error_msg = (
            f"Source file not found or access denied at URL: {source_url} " f"(HTTP {error_code})"
        )
        if error_code == 404 or error_code == 403:
            logger.warning(error_msg)
            return {
                "statusCode": 404,
                "body": error_msg,
            }
        else:
            log_http_error_msg = f"HTTP error during download from {source_url}: {str(http_err)}"
            logger.error(log_http_error_msg, exc_info=True)
            return {
                "statusCode": 502,
                "body": error_msg,
            }
    except Exception as e:
        error_msg = f"Unhandled error during processing: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            "statusCode": 500,
            "body": error_msg,
        }
