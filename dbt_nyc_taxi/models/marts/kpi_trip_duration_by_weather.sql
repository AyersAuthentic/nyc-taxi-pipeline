select
    pickup_borough,
    dropoff_borough,

    case
        when precipitation = 0 then 'No Rain'
        when precipitation > 0 and precipitation <= 0.1 then 'Light Rain'
        when precipitation > 0.1 and precipitation <= 0.3 then 'Moderate Rain'
        when precipitation > 0.3 then 'Heavy Rain'
        else 'No Rain'
    end as precipitation_category,
    percentile_cont(0.5) within group (order by trip_duration_minutes) as median_trip_duration

from {{ ref('fct_trips') }}
group by 1, 2, 3
order by 1, 2, 3
