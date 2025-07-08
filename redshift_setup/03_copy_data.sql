COPY "raw".yellow_tripdata

FROM 's3://<your-bucket>/path/to/file.parquet'

IAM_ROLE '<your-redshift-role-arn>'

FORMAT AS PARQUET;
