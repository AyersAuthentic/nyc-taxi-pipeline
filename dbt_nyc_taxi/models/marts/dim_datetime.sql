with datetime_cte as (
    select distinct
        pickup_datetime
    from {{ ref('stg_yellow_tripdata') }}
    where pickup_datetime is not null
)
select
    {{ dbt_utils.generate_surrogate_key(['pickup_datetime']) }} as datetime_id,
    pickup_datetime,
    extract(year from pickup_datetime) as pickup_year,
    extract(month from pickup_datetime) as pickup_month,
    extract(day from pickup_datetime) as pickup_day,
    extract(hour from pickup_datetime) as pickup_hour,
    extract(minute from pickup_datetime) as pickup_minute,
    extract(dayofweek from pickup_datetime) as pickup_day_of_week
from datetime_cte
