"""Tests for the NOAA Weather data ingestion Lambda function."""

import json
from unittest.mock import MagicMock, patch

import pytest
import requests
from conftest import load_noaa_module


class TestNoaaTransformFunction:
    """Tests for the transform_noaa_response_for_redshift function."""

    def test_transforms_results_to_ndjson(self, sample_noaa_api_response_json):
        app = load_noaa_module()
        ndjson, original = app.transform_noaa_response_for_redshift(
            sample_noaa_api_response_json, "GHCND:USW00094728", "GHCND"
        )

        lines = ndjson.strip().split("\n")
        assert len(lines) == 3

        for line in lines:
            parsed = json.loads(line)
            assert "date" in parsed
            assert "datatype" in parsed
            assert "value" in parsed

    def test_enriches_records_with_metadata(self, sample_noaa_api_response_json):
        app = load_noaa_module()
        ndjson, _ = app.transform_noaa_response_for_redshift(
            sample_noaa_api_response_json, "GHCND:USW00094728", "GHCND"
        )

        first_record = json.loads(ndjson.split("\n")[0])
        assert "ingestion_timestamp" in first_record
        assert first_record["source_dataset"] == "GHCND"
        assert "api_response_metadata" in first_record

    def test_metadata_contains_api_pagination_info(self, sample_noaa_api_response_json):
        app = load_noaa_module()
        ndjson, _ = app.transform_noaa_response_for_redshift(
            sample_noaa_api_response_json, "GHCND:USW00094728", "GHCND"
        )

        record = json.loads(ndjson.split("\n")[0])
        metadata = record["api_response_metadata"]
        assert metadata["offset"] == 1
        assert metadata["count"] == 3
        assert metadata["limit"] == 1000

    def test_preserves_original_response(
        self, sample_noaa_api_response, sample_noaa_api_response_json
    ):
        app = load_noaa_module()
        _, original = app.transform_noaa_response_for_redshift(
            sample_noaa_api_response_json, "GHCND:USW00094728", "GHCND"
        )

        assert original == sample_noaa_api_response

    def test_empty_results_returns_empty_ndjson(self):
        app = load_noaa_module()
        empty_response = json.dumps(
            {"metadata": {"resultset": {"offset": 1, "count": 0, "limit": 1000}}, "results": []}
        )
        ndjson, _ = app.transform_noaa_response_for_redshift(
            empty_response, "GHCND:USW00094728", "GHCND"
        )

        assert ndjson == ""

    def test_invalid_json_raises_error(self):
        app = load_noaa_module()
        with pytest.raises(json.JSONDecodeError):
            app.transform_noaa_response_for_redshift("not valid json", "GHCND:USW00094728", "GHCND")


class TestNoaaParameterValidation:
    """Tests for event parameter validation."""

    def test_missing_station_id_returns_400(self, mock_lambda_context):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()
            event = {
                "datatype_ids": "PRCP,TMAX,TMIN",
                "start_date": "2024-01-01",
                "end_date": "2024-01-31",
            }
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 400
            body = json.loads(result["body"])
            assert "station_id" in body["error"]

    def test_missing_dates_returns_400(self, mock_lambda_context):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()
            event = {
                "station_id": "GHCND:USW00094728",
                "datatype_ids": "PRCP,TMAX,TMIN",
            }
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 400
            body = json.loads(result["body"])
            assert "start_date" in body["error"]
            assert "end_date" in body["error"]

    def test_empty_event_returns_400(self, mock_lambda_context):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()
            result = app.lambda_handler({}, mock_lambda_context)

            assert result["statusCode"] == 400


class TestNoaaEnvironmentValidation:
    """Tests for environment variable validation."""

    def test_missing_bucket_name_returns_500(self, mock_lambda_context):
        with patch.dict("os.environ", {}, clear=True):
            app = load_noaa_module()
            event = {
                "station_id": "GHCND:USW00094728",
                "datatype_ids": "PRCP,TMAX,TMIN",
                "start_date": "2024-01-01",
                "end_date": "2024-01-31",
            }
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 500
            body = json.loads(result["body"])
            assert "BRONZE_BUCKET_NAME" in body["error"]

    def test_missing_secret_arn_returns_500(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}, clear=True):
            app = load_noaa_module()
            event = {
                "station_id": "GHCND:USW00094728",
                "datatype_ids": "PRCP,TMAX,TMIN",
                "start_date": "2024-01-01",
                "end_date": "2024-01-31",
            }
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 500
            body = json.loads(result["body"])
            assert "NOAA_API_KEY_SECRET_ARN" in body["error"]


class TestNoaaSuccessPath:
    """Tests for successful ingestion flow."""

    def test_successful_ingestion_returns_200(self, mock_lambda_context, sample_noaa_api_response):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()

            app.secrets_manager_client.get_secret_value.return_value = {
                "SecretString": json.dumps({"NOAA_API_TOKEN": "test-token-123"})
            }

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.text = json.dumps(sample_noaa_api_response)
            mock_response.raise_for_status = MagicMock()

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {
                    "station_id": "GHCND:USW00094728",
                    "datatype_ids": "PRCP,TMAX,TMIN",
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31",
                }
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 200
                assert result["records_processed"] == 3
                assert "s3_uri" in result

    def test_s3_keys_follow_partition_schema(self, mock_lambda_context, sample_noaa_api_response):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()

            app.secrets_manager_client.get_secret_value.return_value = {
                "SecretString": json.dumps({"NOAA_API_TOKEN": "test-token-123"})
            }

            mock_response = MagicMock()
            mock_response.text = json.dumps(sample_noaa_api_response)
            mock_response.raise_for_status = MagicMock()

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {
                    "station_id": "GHCND:USW00094728",
                    "datatype_ids": "PRCP,TMAX,TMIN",
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31",
                }
                result = app.lambda_handler(event, mock_lambda_context)

                expected_prefix = (
                    "noaa-weather/dataset=GHCND/station_id=GHCND:USW00094728" "/year=2024/month=01"
                )
                assert result["redshift_s3_key"].startswith(expected_prefix)
                assert result["redshift_s3_key"].endswith("_redshift.ndjson")
                assert result["original_s3_key"].endswith("_original.json")

    def test_uploads_both_ndjson_and_original(self, mock_lambda_context, sample_noaa_api_response):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()

            app.secrets_manager_client.get_secret_value.return_value = {
                "SecretString": json.dumps({"NOAA_API_TOKEN": "test-token-123"})
            }

            mock_response = MagicMock()
            mock_response.text = json.dumps(sample_noaa_api_response)
            mock_response.raise_for_status = MagicMock()

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {
                    "station_id": "GHCND:USW00094728",
                    "datatype_ids": "PRCP,TMAX,TMIN",
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31",
                }
                app.lambda_handler(event, mock_lambda_context)

                assert app.s3_client.put_object.call_count == 2


class TestNoaaErrorHandling:
    """Tests for API error handling."""

    def test_api_401_returns_error(self, mock_lambda_context):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()

            app.secrets_manager_client.get_secret_value.return_value = {
                "SecretString": json.dumps({"NOAA_API_TOKEN": "bad-token"})
            }

            mock_response = MagicMock()
            mock_response.status_code = 401
            mock_response.text = "Unauthorized"
            mock_response.json.side_effect = json.JSONDecodeError("", "", 0)
            mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(
                response=mock_response
            )

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {
                    "station_id": "GHCND:USW00094728",
                    "datatype_ids": "PRCP,TMAX,TMIN",
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31",
                }
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 401

    def test_invalid_date_format_returns_400(self, mock_lambda_context):
        with patch.dict(
            "os.environ",
            {"BRONZE_BUCKET_NAME": "test-bucket", "NOAA_API_KEY_SECRET_ARN": "arn:fake"},
        ):
            app = load_noaa_module()

            app.secrets_manager_client.get_secret_value.return_value = {
                "SecretString": json.dumps({"NOAA_API_TOKEN": "test-token"})
            }

            mock_response = MagicMock()
            mock_response.text = json.dumps({"metadata": {}, "results": []})
            mock_response.raise_for_status = MagicMock()

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {
                    "station_id": "GHCND:USW00094728",
                    "datatype_ids": "PRCP,TMAX,TMIN",
                    "start_date": "badformat",
                    "end_date": "2024-01-31",
                }
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 400


class TestNoaaGetApiToken:
    """Tests for the get_noaa_api_token helper function."""

    def test_extracts_token_from_json_secret(self):
        app = load_noaa_module()
        app.secrets_manager_client.get_secret_value.return_value = {
            "SecretString": json.dumps({"NOAA_API_TOKEN": "my-secret-token"})
        }

        token = app.get_noaa_api_token("arn:aws:secretsmanager:us-east-1:123:secret:test")
        assert token == "my-secret-token"

    def test_handles_plain_string_secret(self):
        app = load_noaa_module()
        app.secrets_manager_client.get_secret_value.return_value = {
            "SecretString": "plain-token-string"
        }

        token = app.get_noaa_api_token("arn:fake")
        assert token == "plain-token-string"

    def test_binary_secret_raises_error(self):
        app = load_noaa_module()
        app.secrets_manager_client.get_secret_value.return_value = {
            "SecretBinary": b"binary-secret"
        }

        with pytest.raises(ValueError, match="binary format"):
            app.get_noaa_api_token("arn:fake")
