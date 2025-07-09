select
    station as station_id,
    datatype as measurement_type,
    value as measurement_value,
    attributes,
    source_dataset,


    cast(date as timestamp) as observation_date,


    current_timestamp as ingestion_timestamp

from {{ source('raw_data', 'noaa_weather_data') }}
