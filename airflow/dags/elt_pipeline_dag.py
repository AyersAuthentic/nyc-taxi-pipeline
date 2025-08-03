from __future__ import annotations

import pendulum
from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.providers.amazon.aws.operators.redshift_sql import RedshiftSQLOperator

# --- Best Practices: Define Variables ---
AWS_REGION = "us-east-1"
AWS_CONN_ID = "aws_default"  # Airflow connection for Redshift
REDSHIFT_CONN_ID = "redshift_default"  # Airflow connection for Redshift

AWS_LAMBDA_FUNCTION_TAXI = "nyc-taxi-pipeline-nyc-taxi-ingest-dev"
AWS_LAMBDA_FUNCTION_WEATHER = "nyc-taxi-pipeline-noaa-weather-ingest-dev"

DBT_PROJECT_DIR = "/home/ec2-user/app/dbt_nyc_taxi"  # Path to your dbt project on the EC2
VENV_ACTIVATE_CMD = "source /home/ec2-user/airflow_project/venv/bin/activate"
DBT_COMMAND = (
    f"source /home/ec2-user/.dbt/dbt_env.sh && "
    f"cd {DBT_PROJECT_DIR} && "
    f"{VENV_ACTIVATE_CMD} && "
    f"dbt deps && dbt seed && dbt run && dbt test"
)

# --- SQL COPY Command Templates ---
# We use Jinja templating to dynamically insert the S3 key from the Lambda output (XCom)
COPY_TAXI_SQL = """
    COPY "raw".yellow_tripdata
    FROM '{{ task_instance.xcom_pull(task_ids='ingest_nyc_taxi_data', key='return_value')['s3_key'] }}'
    IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
    FORMAT AS PARQUET;
"""

COPY_WEATHER_SQL = """
    COPY "raw".noaa_weather_data
    FROM '{{ task_instance.xcom_pull(task_ids='ingest_noaa_weather_data', key='return_value')['redshift_s3_key'] }}'
    IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
    FORMAT AS JSON 'auto';
"""


with DAG(
    dag_id="nyc_taxi_elt_pipeline",
    schedule="@daily",
    start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),
    catchup=False,
    is_paused_upon_creation=True,
    tags=["taxi_data", "dbt", "elt"],
    doc_md="""
    ### NYC Taxi ELT Pipeline

    This DAG orchestrates the entire ELT process for the NYC Taxi project.

    **Purpose:**
    The pipeline ingests raw data from two external sources (NYC TLC and NOAA),
    loads it into a Redshift data warehouse, and then uses dbt to transform
    the raw data into a clean, analytical star schema.

    **Pipeline Stages:**

    1.  **Ingest (Extract):** Two parallel tasks trigger AWS Lambda functions
        to fetch the latest data. These functions save the raw files to the
        S3 Bronze bucket and push the S3 file path to XComs.

    2.  **Load:** Two parallel tasks use the `RedshiftSQLOperator` to run a
        `COPY` command. They dynamically pull the S3 file path from the
        corresponding ingestion task via XComs, loading the raw data into Redshift.

    3.  **Transform:** A final task runs `dbt build` using the `BashOperator`.
        This command orchestrates the entire dbt project, building the
        `staging` and `marts` schemas in Redshift.
    """,
) as dag:

    # --- Ingestion Tasks ---
    ingest_weather_data = LambdaInvokeFunctionOperator(
        task_id="ingest_noaa_weather_data",
        function_name=AWS_LAMBDA_FUNCTION_WEATHER,
        payload='{"start_date": "2024-01-01", "end_date": "2024-01-31"}',
        aws_conn_id=AWS_CONN_ID,
        region_name=AWS_REGION,
        do_xcom_push=True,  # This tells the operator to push its return value to XComs
    )

    ingest_taxi_data = LambdaInvokeFunctionOperator(
        task_id="ingest_nyc_taxi_data",
        function_name=AWS_LAMBDA_FUNCTION_TAXI,
        payload='{"year": "2024", "month": "1"}',
        aws_conn_id=AWS_CONN_ID,
        region_name=AWS_REGION,
        do_xcom_push=True,  # This tells the operator to push its return value to XComs
    )

    # --- New Loading Tasks ---
    load_weather_data_to_redshift = RedshiftSQLOperator(
        task_id="load_weather_data_to_redshift",
        sql=COPY_WEATHER_SQL,
        redshift_conn_id=REDSHIFT_CONN_ID,
    )

    load_taxi_data_to_redshift = RedshiftSQLOperator(
        task_id="load_taxi_data_to_redshift", sql=COPY_TAXI_SQL, redshift_conn_id=REDSHIFT_CONN_ID
    )

    # --- Transformation Task ---
    transform_data_with_dbt = BashOperator(
        task_id="transform_data_with_dbt",
        bash_command=DBT_COMMAND,
    )

    # --- Set Task Dependencies ---
    # Ingest -> Load -> Transform
    ingest_weather_data >> load_weather_data_to_redshift
    ingest_taxi_data >> load_taxi_data_to_redshift
    [load_weather_data_to_redshift, load_taxi_data_to_redshift] >> transform_data_with_dbt
