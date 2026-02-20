"""Shared fixtures for NYC Taxi Pipeline tests."""

import importlib
import json
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# The Lambda source directories contain `lambda` in the path, which is a Python
# reserved keyword and cannot be used in normal import statements. We add the
# individual function directories to sys.path so they can be imported by module name.
PROJECT_ROOT = Path(__file__).parent.parent

TAXI_LAMBDA_DIR = str(
    PROJECT_ROOT / "terraform" / "modules" / "lambda" / "lambda_functions" / "nyc_taxi_ingestion"
)
NOAA_LAMBDA_DIR = str(
    PROJECT_ROOT
    / "terraform"
    / "modules"
    / "lambda"
    / "lambda_functions"
    / "noaa_weather_ingestion"
)


@pytest.fixture(autouse=True)
def _patch_boto3_and_load_modules():
    """
    Patch boto3 clients before importing Lambda modules so the module-level
    client instantiation doesn't hit real AWS.
    """
    with patch("boto3.client") as mock_boto:
        mock_boto.return_value = MagicMock()

        # Ensure Lambda dirs are on sys.path for import
        for d in (TAXI_LAMBDA_DIR, NOAA_LAMBDA_DIR):
            if d not in sys.path:
                sys.path.insert(0, d)

        # Force reimport on each test to pick up fresh mocks
        for mod_name in ("app",):
            if mod_name in sys.modules:
                del sys.modules[mod_name]

        yield mock_boto


@pytest.fixture
def mock_lambda_context():
    """Mock AWS Lambda context object."""
    context = MagicMock()
    context.aws_request_id = "test-request-id-12345"
    context.function_name = "test-function"
    return context


@pytest.fixture
def sample_noaa_api_response():
    """Sample NOAA API JSON response with weather data."""
    return {
        "metadata": {
            "resultset": {
                "offset": 1,
                "count": 3,
                "limit": 1000,
            }
        },
        "results": [
            {
                "date": "2024-01-01T00:00:00",
                "datatype": "TMAX",
                "station": "GHCND:USW00094728",
                "attributes": ",,W,2400",
                "value": 44,
            },
            {
                "date": "2024-01-01T00:00:00",
                "datatype": "TMIN",
                "station": "GHCND:USW00094728",
                "attributes": ",,W,2400",
                "value": 33,
            },
            {
                "date": "2024-01-01T00:00:00",
                "datatype": "PRCP",
                "station": "GHCND:USW00094728",
                "attributes": ",,W,2400",
                "value": 0,
            },
        ],
    }


@pytest.fixture
def sample_noaa_api_response_json(sample_noaa_api_response):
    """Sample NOAA API response as a JSON string."""
    return json.dumps(sample_noaa_api_response)


def load_taxi_module():
    """Import the NYC taxi ingestion Lambda app module."""
    if "app" in sys.modules:
        del sys.modules["app"]
    if TAXI_LAMBDA_DIR not in sys.path:
        sys.path.insert(0, TAXI_LAMBDA_DIR)
    if NOAA_LAMBDA_DIR in sys.path:
        sys.path.remove(NOAA_LAMBDA_DIR)
    return importlib.import_module("app")


def load_noaa_module():
    """Import the NOAA weather ingestion Lambda app module."""
    if "app" in sys.modules:
        del sys.modules["app"]
    if NOAA_LAMBDA_DIR not in sys.path:
        sys.path.insert(0, NOAA_LAMBDA_DIR)
    if TAXI_LAMBDA_DIR in sys.path:
        sys.path.remove(TAXI_LAMBDA_DIR)
    return importlib.import_module("app")
