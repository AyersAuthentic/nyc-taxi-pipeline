from __future__ import annotations

import pendulum
from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator

AWS_LAMBDA_FUNCTION_TAXI = "nyc-taxi-pipeline-nyc-taxi-ingest-dev"
AWS_LAMBDA_FUNCTION_WEATHER = "nyc-taxi-pipeline-noaa-weather-ingest-dev"
DBT_PROJECT_DIR = "/home/ec2-user/airflow_project/nyc-taxi-pipeline/dbt_nyc_taxi"
VENV_ACTIVATE_CMD = "source /home/ec2-user/airflow_project/venv/bin/activate"
AWS_REGION = "us-east-1"


DBT_BUILD_CMD = (
    "source /home/ec2-user/.dbt/dbt_env.sh && "
    f"cd {DBT_PROJECT_DIR} && "
    f"{VENV_ACTIVATE_CMD} && "
    "dbt build"
)


with DAG(
    dag_id="nyc_taxi_elt_pipeline",
    schedule="@daily",
    start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),
    catchup=False,
    is_paused_upon_creation=True,
    tags=["taxi_data", "dbt", "elt"],
    doc_md="""
    ## NYC Taxi ELT Pipeline

    This DAG orchestrates the ELT process for the NYC Taxi project.

    ### Steps:
    1.  **Ingest Data**: Triggers Lambda functions to fetch the latest taxi and weather data.
        The data is loaded into the `raw` schema in Redshift.
    2.  **Transform Data**: Runs `dbt build` to execute all dbt models, which transforms
        the raw data into the `staging` and `marts` schemas.
    """,
) as dag:

    ingest_weather_data = LambdaInvokeFunctionOperator(
        task_id="ingest_noaa_weather_data",
        function_name=AWS_LAMBDA_FUNCTION_WEATHER,
        payload='{"start_date": "2024-02-01", "end_date": "2024-02-31"}',
        aws_conn_id=None,
        region_name=AWS_REGION,
    )

    ingest_taxi_data = LambdaInvokeFunctionOperator(
        task_id="ingest_nyc_taxi_data",
        function_name=AWS_LAMBDA_FUNCTION_TAXI,
        payload='{"year": "2024", "month": "2", "taxi_type": "yellow"}',
        aws_conn_id=None,
        region_name=AWS_REGION,
    )

    transform_data_with_dbt = BashOperator(
        task_id="transform_data_with_dbt",
        bash_command=DBT_BUILD_CMD,
    )

    [ingest_weather_data, ingest_taxi_data] >> transform_data_with_dbt
