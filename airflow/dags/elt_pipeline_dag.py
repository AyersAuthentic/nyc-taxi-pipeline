from __future__ import annotations

import json

import pendulum
from airflow.decorators import task
from airflow.exceptions import AirflowException
from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

# ---- Config ----
AWS_REGION = "us-east-1"
AWS_CONN_ID = "aws_default"
REDSHIFT_CONN_ID = "redshift_default"

AWS_LAMBDA_FUNCTION_TAXI = "nyc-taxi-pipeline-nyc-taxi-ingest-dev"
AWS_LAMBDA_FUNCTION_WEATHER = "nyc-taxi-pipeline-noaa-weather-ingest-dev"

DBT_PROJECT_DIR = "/home/ec2-user/airflow_project/nyc-taxi-pipeline/dbt_nyc_taxi"
VENV_ACTIVATE_CMD = "source /home/ec2-user/airflow_project/venv/bin/activate"
DBT_COMMAND = (
    f"source /home/ec2-user/.dbt/dbt_env.sh && "
    f"cd {DBT_PROJECT_DIR} && "
    f"{VENV_ACTIVATE_CMD} && "
    f"dbt deps && dbt seed && dbt run && dbt test"
)

# ---- SQL Statements ----
TRANSACTIONAL_TAXI_LOAD_SQL = """
BEGIN;

-- 1. Create a temporary table with the same structure as our raw table.
CREATE TEMP TABLE temp_yellow_tripdata (LIKE "raw".yellow_tripdata);

-- 2. Copy the new data from S3 into the temporary table.
COPY temp_yellow_tripdata
FROM '{{ ti.xcom_pull(task_ids="taxi_s3_uri") }}'
IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
FORMAT AS PARQUET;

-- 3. Delete any records from the main raw table that exist in our temp table.
DELETE FROM "raw".yellow_tripdata
USING temp_yellow_tripdata
WHERE "raw".yellow_tripdata.tpep_pickup_datetime = temp_yellow_tripdata.tpep_pickup_datetime
AND "raw".yellow_tripdata.vendorid = temp_yellow_tripdata.vendorid;

-- 4. Insert all the new records from the temporary table into the main raw table.
INSERT INTO "raw".yellow_tripdata
SELECT * FROM temp_yellow_tripdata;

-- The temporary table is automatically dropped at the end of the session.
END;
"""

CLEANUP_WEATHER_SQL = (
    'DELETE FROM "raw".noaa_weather_data '
    "WHERE date_trunc('month', CAST(date AS DATE)) = "
    "date_trunc('month', CAST('{{ (data_interval_end - macros.dateutil.relativedelta.relativedelta(months=2)).strftime(\"%Y-%m-%d\") }}' AS DATE));"
)

# COPY commands now pull from XComs
COPY_TAXI_SQL = """
COPY "raw".yellow_tripdata
FROM '{{ ti.xcom_pull(task_ids="taxi_s3_uri") }}'
IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
FORMAT AS PARQUET;
"""

COPY_WEATHER_SQL = """
COPY "raw".noaa_weather_data
FROM '{{ ti.xcom_pull(task_ids="weather_s3_uri") }}'
IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
FORMAT AS JSON 'auto';
"""

with DAG(
    dag_id="nyc_taxi_elt_pipeline",
    schedule="0 5 15 * *",
    start_date=pendulum.datetime(2025, 6, 1, tz="UTC"),
    catchup=True,
    is_paused_upon_creation=True,
    tags=["taxi_data", "dbt", "elt"],
    doc_md="""
    ### NYC Taxi ELT Pipeline
    This DAG orchestrates an idempotent ELT process. It deletes data
    for the target period before loading new data to prevent duplicates.
    """,
) as dag:
    # ---- Ingest tasks  ----
    ingest_weather_data = LambdaInvokeFunctionOperator(
        task_id="ingest_noaa_weather_data",
        function_name=AWS_LAMBDA_FUNCTION_WEATHER,
        payload=json.dumps(
            {
                "dataset_id": "GHCND",
                "station_id": "GHCND:USW00094728",
                "datatype_ids": "PRCP,TEMP,TAVG,TMAX,TMIN,WT16,WT14",
                "start_date": "{{ (data_interval_end - macros.dateutil.relativedelta.relativedelta(months=2)).strftime('%Y-%m-01') }}",
                "end_date": "{{ (data_interval_end - macros.dateutil.relativedelta.relativedelta(months=2)).end_of('month').strftime('%Y-%m-%d') }}",
                "units": "standard",
            }
        ),
        aws_conn_id=AWS_CONN_ID,
        region_name=AWS_REGION,
        do_xcom_push=True,
    )

    ingest_taxi_data = LambdaInvokeFunctionOperator(
        task_id="ingest_nyc_taxi_data",
        function_name=AWS_LAMBDA_FUNCTION_TAXI,
        payload=json.dumps(
            {
                "year": "{{ (data_interval_end - macros.dateutil.relativedelta.relativedelta(months=2)).year }}",
                "month": "{{ (data_interval_end - macros.dateutil.relativedelta.relativedelta(months=2)).month }}",
                "taxi_type": "yellow",
            }
        ),
        aws_conn_id=AWS_CONN_ID,
        region_name=AWS_REGION,
        do_xcom_push=True,
    )

    # ---- Normalization tasks ----
    @task(task_id="weather_s3_uri")
    def weather_s3_uri(ti=None) -> str:
        raw = ti.xcom_pull(task_ids="ingest_noaa_weather_data")
        data = json.loads(raw) if isinstance(raw, str) else raw
        status = int(data.get("statusCode", 200))
        if status != 200:
            raise AirflowException(f"NOAA ingest failed: {data}")
        uri = data.get("redshift_s3_uri") or data.get("s3_uri")
        if not uri:
            raise AirflowException(f"Missing S3 URI in NOAA XCom: keys={list(data.keys())}")
        return uri

    @task(task_id="taxi_s3_uri")
    def taxi_s3_uri(ti=None) -> str:
        raw = ti.xcom_pull(task_ids="ingest_nyc_taxi_data")
        data = json.loads(raw) if isinstance(raw, str) else raw
        status = int(data.get("statusCode", 200))
        if status != 200:
            raise AirflowException(f"TLC ingest failed: {data}")
        uri = data.get("s3_uri") or data.get("redshift_s3_uri")
        if not uri:
            raise AirflowException(f"Missing S3 URI in TLC XCom: keys={list(data.keys())}")
        return uri

    weather_uri = weather_s3_uri()
    taxi_uri = taxi_s3_uri()

    # ---- Cleanup tasks ----
    cleanup_raw_weather_table = SQLExecuteQueryOperator(
        task_id="cleanup_raw_weather_table",
        sql=CLEANUP_WEATHER_SQL,
        conn_id=REDSHIFT_CONN_ID,
    )

    # ---- Load tasks ----
    load_weather_data_to_redshift = SQLExecuteQueryOperator(
        task_id="load_weather_data_to_redshift",
        sql=COPY_WEATHER_SQL,
        conn_id=REDSHIFT_CONN_ID,
    )

    idempotent_load_taxi_data = SQLExecuteQueryOperator(
        task_id="idempotent_load_taxi_data",
        sql=TRANSACTIONAL_TAXI_LOAD_SQL,
        conn_id=REDSHIFT_CONN_ID,
        split_statements=True,
    )

    # ---- Transform ----
    transform_data_with_dbt = BashOperator(
        task_id="transform_data_with_dbt",
        bash_command=DBT_COMMAND,
    )

    # ---- Orchestration ----
    # Dependency chain: Ingest -> Normalize URI -> Cleanup -> Load -> Transform
    ingest_weather_data >> weather_uri >> cleanup_raw_weather_table >> load_weather_data_to_redshift
    ingest_taxi_data >> taxi_uri >> idempotent_load_taxi_data

    [load_weather_data_to_redshift, idempotent_load_taxi_data] >> transform_data_with_dbt
