with source_data as (
    select raw_data from {{ source('raw_data', 'noaa_weather_data') }}
)

select
    cast(r.date as timestamp) as observation_date,
    r.datatype::varchar as measurement_type,
    cast(r.value as numeric) as measurement_value,
    r.station::varchar as station_id
from
    source_data s,
    s.raw_data.results r
