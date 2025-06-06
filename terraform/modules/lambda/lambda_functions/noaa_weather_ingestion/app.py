import json
import logging
import os

import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")
secrets_manager_client = boto3.client("secretsmanager")

NOAA_API_BASE_URL = os.getenv("NOAA_API_BASE_URL", "https://www.ncei.noaa.gov/cdo-web/api/v2/")
HTTP_REQUEST_TIMEOUT = int(os.getenv("HTTP_REQUEST_TIMEOUT", "60"))
NOAA_API_KEY_SECRET_ARN = os.getenv("NOAA_API_KEY_SECRET_ARN")


def get_noaa_api_token(secret_arn):
    """Retrieves the NOAA API token from AWS Secrets Manager."""
    try:
        logger.info("Fetching NOAA API token from Secrets Manager secret")
        secret_value_response = secrets_manager_client.get_secret_value(SecretId=secret_arn)

        if "SecretString" in secret_value_response:
            secret = secret_value_response["SecretString"]
            try:
                return json.loads(secret).get("NOAA_API_TOKEN", secret)
            except json.JSONDecodeError:
                return secret
        else:
            logger.error("API token found in binary format, which is not expected.")
            raise ValueError("API token in unexpected binary format")
    except Exception as e:
        logger.error(
            f"Error retrieving NOAA API token from Secrets Manager: {str(e)}", exc_info=True
        )
        raise e


def lambda_handler(event, context):
    """
    Fetches weather data from NOAA API for a given station, data types, and date range,
    then stores the raw JSON response in S3 Bronze.
    """
    try:
        logger.info(f"AWS Request ID: {context.aws_request_id} - Received event: {event}")

        station_id = event.get("station_id")
        datatype_ids_str = event.get("datatype_ids")
        dataset_id = event.get("dataset_id", "GHCND")
        start_date = event.get("start_date")
        end_date = event.get("end_date")
        units = event.get("units", "metric")

        required_params = {
            "station_id": station_id,
            "datatype_ids": datatype_ids_str,
            "start_date": start_date,
            "end_date": end_date,
        }
        missing_params = [k for k, v in required_params.items() if not v]
        if missing_params:
            error_msg = f"Missing required event parameters: {', '.join(missing_params)}."
            logger.error(error_msg)
            return {"statusCode": 400, "body": json.dumps({"error": error_msg})}

        bronze_bucket_name = os.environ.get("BRONZE_BUCKET_NAME")
        noaa_api_key_secret_arn = os.environ.get("NOAA_API_KEY_SECRET_ARN")

        if not bronze_bucket_name:
            error_msg = "Environment variable BRONZE_BUCKET_NAME not set."
            logger.error(error_msg)
            return {"statusCode": 500, "body": json.dumps({"error": error_msg})}
        if not noaa_api_key_secret_arn:
            error_msg = "Environment variable NOAA_API_KEY_SECRET_ARN not set."
            logger.error(error_msg)
            return {"statusCode": 500, "body": json.dumps({"error": error_msg})}

        noaa_api_token = get_noaa_api_token(noaa_api_key_secret_arn)
        if not noaa_api_token:
            error_msg = "Failed to retrieve NOAA API token."
            logger.error(error_msg)
            return {"statusCode": 500, "body": json.dumps({"error": error_msg})}

        headers = {"token": noaa_api_token}

        api_params = {
            "datasetid": dataset_id,
            "stationid": station_id,
            "datatypeid": datatype_ids_str,
            "startdate": start_date,
            "enddate": end_date,
            "units": units,
            "limit": 1000,
        }

        endpoint_url = f"{NOAA_API_BASE_URL}/data"
        logger.info(f"Querying NOAA API: {endpoint_url} with params: {api_params}")

        response = requests.get(
            endpoint_url, headers=headers, params=api_params, timeout=HTTP_REQUEST_TIMEOUT
        )
        response.raise_for_status()

        weather_data_json = response.text

        try:
            year = start_date.split("-")[0]
            month = start_date.split("-")[1]
        except IndexError:
            error_msg = "Invalid start_date format. Expected YYYY-MM-DD."
            logger.error(error_msg)
            return {"statusCode": 400, "body": json.dumps({"error": error_msg})}

        s3_file_name = f"{start_date}_to_{end_date}_data.json"
        destination_s3_key = (
            f"noaa-weather/dataset={dataset_id}/station_id={station_id}/"
            f"year={year}/month={month}/{s3_file_name}"
        )

        logger.info(f"Uploading data to s3://{bronze_bucket_name}/{destination_s3_key}")

        s3_client.put_object(
            Bucket=bronze_bucket_name,
            Key=destination_s3_key,
            Body=weather_data_json,
            ContentType="application/json",
        )

        success_msg = (
            f"Successfully fetched NOAA data and stored in S3: "
            f"s3://{bronze_bucket_name}/{destination_s3_key}"
        )
        logger.info(success_msg)
        return {
            "statusCode": 200,
            "body": json.dumps({"message": success_msg, "s3_key": destination_s3_key}),
        }

    except requests.exceptions.HTTPError as http_err:
        error_code = http_err.response.status_code
        api_error_details = http_err.response.text[:500]
        error_msg_log = (
            f"HTTP error {error_code} from NOAA API for station {station_id}, "
            f"dates {start_date}-{end_date}. Details: {api_error_details}"
        )
        logger.error(error_msg_log, exc_info=True)

        try:
            noaa_error_body = http_err.response.json()
        except json.JSONDecodeError:
            noaa_error_body = {
                "error": "NOAA API did not return valid JSON.",
                "details": api_error_details,
            }

        return {
            "statusCode": (error_code if error_code >= 400 else 502),
            "body": json.dumps(noaa_error_body),
        }
    except Exception as e:
        error_msg = (
            f"Unhandled error during processing for "
            f"station {station_id}, dates {start_date}-{end_date}: {str(e)}"
        )
        logger.error(error_msg, exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error", "details": str(e)}),
        }
