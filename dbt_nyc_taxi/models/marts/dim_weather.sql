select
    observation_date,

    max(case when measurement_type = 'PRCP' then measurement_value else null end) as prcp,
    max(case when measurement_type = 'TMAX' then measurement_value else null end) as tmax,
    max(case when measurement_type = 'TMIN' then measurement_value else null end) as tmin,


    (tmax + tmin) / 2.0 as tavg

from {{ ref('stg_noaa_weather_data') }}
group by 1
