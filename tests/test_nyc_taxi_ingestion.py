"""Tests for the NYC Taxi data ingestion Lambda function."""

import json
from io import BytesIO
from unittest.mock import MagicMock, patch

import requests
from conftest import load_taxi_module


class TestNycTaxiParameterValidation:
    """Tests for event parameter validation."""

    def test_missing_year_returns_400(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()
            event = {"month": "01", "taxi_type": "yellow"}
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 400
            body = json.loads(result["body"])
            assert "error" in body

    def test_missing_month_returns_400(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()
            event = {"year": "2024", "taxi_type": "yellow"}
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 400

    def test_missing_taxi_type_returns_400(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()
            event = {"year": "2024", "month": "01"}
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 400

    def test_empty_event_returns_400(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()
            result = app.lambda_handler({}, mock_lambda_context)

            assert result["statusCode"] == 400


class TestNycTaxiEnvironmentValidation:
    """Tests for environment variable validation."""

    def test_missing_bronze_bucket_returns_500(self, mock_lambda_context):
        with patch.dict("os.environ", {}, clear=True):
            app = load_taxi_module()
            event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
            result = app.lambda_handler(event, mock_lambda_context)

            assert result["statusCode"] == 500
            body = json.loads(result["body"])
            assert "BRONZE_BUCKET_NAME" in body["error"]


class TestNycTaxiMonthPadding:
    """Tests for month zero-padding logic."""

    def test_single_digit_month_gets_zero_padded(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_response = MagicMock()
            mock_response.raw = BytesIO(b"fake-parquet-data")
            mock_response.raise_for_status = MagicMock()
            mock_response.__enter__ = MagicMock(return_value=mock_response)
            mock_response.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {"year": "2024", "month": "3", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 200
                assert "month=03" in result["destination_key"]

    def test_double_digit_month_unchanged(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_response = MagicMock()
            mock_response.raw = BytesIO(b"fake-parquet-data")
            mock_response.raise_for_status = MagicMock()
            mock_response.__enter__ = MagicMock(return_value=mock_response)
            mock_response.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {"year": "2024", "month": "12", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 200
                assert "month=12" in result["destination_key"]


class TestNycTaxiSuccessPath:
    """Tests for successful ingestion flow."""

    def test_successful_download_returns_200(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_response = MagicMock()
            mock_response.raw = BytesIO(b"fake-parquet-data")
            mock_response.raise_for_status = MagicMock()
            mock_response.__enter__ = MagicMock(return_value=mock_response)
            mock_response.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 200
                assert "s3_uri" in result
                assert "test-bucket" in result["s3_uri"]

    def test_s3_key_follows_partition_schema(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_response = MagicMock()
            mock_response.raw = BytesIO(b"fake-parquet-data")
            mock_response.raise_for_status = MagicMock()
            mock_response.__enter__ = MagicMock(return_value=mock_response)
            mock_response.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {"year": "2024", "month": "06", "taxi_type": "green"}
                result = app.lambda_handler(event, mock_lambda_context)

                key = result["destination_key"]
                assert key == (
                    "nyc-taxi/trip_type=green/year=2024/month=06/" "green_tripdata_2024-06.parquet"
                )

    def test_upload_called_with_correct_bucket_and_key(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "my-bronze-bucket"}):
            app = load_taxi_module()

            mock_response = MagicMock()
            mock_response.raw = BytesIO(b"fake-parquet-data")
            mock_response.raise_for_status = MagicMock()
            mock_response.__enter__ = MagicMock(return_value=mock_response)
            mock_response.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_response):
                event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
                app.lambda_handler(event, mock_lambda_context)

                app.s3_client.upload_fileobj.assert_called_once()
                call_args = app.s3_client.upload_fileobj.call_args
                assert call_args[0][1] == "my-bronze-bucket"
                assert "yellow_tripdata_2024-01.parquet" in call_args[0][2]


class TestNycTaxiErrorHandling:
    """Tests for HTTP and general error handling."""

    def test_http_404_returns_404(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_resp = MagicMock()
            mock_resp.status_code = 404
            http_error = requests.exceptions.HTTPError(response=mock_resp)

            mock_ctx = MagicMock()
            mock_ctx.__enter__ = MagicMock(side_effect=http_error)
            mock_ctx.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_ctx):
                event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 404

    def test_http_403_returns_404(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_resp = MagicMock()
            mock_resp.status_code = 403
            http_error = requests.exceptions.HTTPError(response=mock_resp)

            mock_ctx = MagicMock()
            mock_ctx.__enter__ = MagicMock(side_effect=http_error)
            mock_ctx.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_ctx):
                event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 404

    def test_http_500_returns_502(self, mock_lambda_context):
        with patch.dict("os.environ", {"BRONZE_BUCKET_NAME": "test-bucket"}):
            app = load_taxi_module()

            mock_resp = MagicMock()
            mock_resp.status_code = 500
            http_error = requests.exceptions.HTTPError(response=mock_resp)

            mock_ctx = MagicMock()
            mock_ctx.__enter__ = MagicMock(side_effect=http_error)
            mock_ctx.__exit__ = MagicMock(return_value=False)

            with patch.object(app.requests, "get", return_value=mock_ctx):
                event = {"year": "2024", "month": "01", "taxi_type": "yellow"}
                result = app.lambda_handler(event, mock_lambda_context)

                assert result["statusCode"] == 502
