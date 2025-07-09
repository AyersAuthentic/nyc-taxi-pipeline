COPY "raw".yellow_tripdata

FROM 's3://nyc-taxi-pipeline-bronze-825088006006/nyc-taxi/trip_type=yellow/year=2024/month=01/yellow_tripdata_2024-01.parquet'

IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'

FORMAT AS PARQUET;

COPY "raw".noaa_weather_data
FROM 's3://nyc-taxi-pipeline-bronze-825088006006/noaa-weather/dataset=GHCND/station_id=GHCND:USW00094728/year=2024/month=01/2024-01-01_to_2024-01-05_data.json'
IAM_ROLE 'arn:aws:iam::825088006006:role/nyc-taxi-pipeline-Role-Redshift-Serverless-dev'
FORMAT AS JSON 'auto';
