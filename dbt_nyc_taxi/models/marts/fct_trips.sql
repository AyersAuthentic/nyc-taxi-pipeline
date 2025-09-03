with trips as (
    select * from {{ ref('stg_yellow_tripdata') }}
),

zones as (
    select * from {{ ref('dim_zones') }}
),

weather as (
    select * from {{ ref('dim_weather') }}
)

select
    trips.tripid,
    trips.vendor_id,
    trips.ratecode_id,
    trips.payment_type,
    trips.pickup_location_id,
    pickup_zone.borough as pickup_borough,
    pickup_zone.zone as pickup_zone,
    trips.dropoff_location_id,
    dropoff_zone.borough as dropoff_borough,
    dropoff_zone.zone as dropoff_zone,

    trips.pickup_datetime,
    trips.dropoff_datetime,

    trips.store_and_fwd_flag,
    trips.passenger_count,
    trips.trip_distance,


    datediff(minute, trips.pickup_datetime, trips.dropoff_datetime) as trip_duration_minutes,


    trips.fare_amount,
    trips.extra,
    trips.mta_tax,
    trips.tip_amount,
    trips.tolls_amount,
    trips.improvement_surcharge,
    trips.total_amount,


    weather.prcp as precipitation,
    weather.tavg as average_temp,
    weather.tmax as max_temp,
    weather.tmin as min_temp


from trips
inner join zones as pickup_zone
    on trips.pickup_location_id = pickup_zone.location_id
inner join zones as dropoff_zone
    on trips.dropoff_location_id = dropoff_zone.location_id
inner join weather
    on cast(trips.pickup_datetime as date) = weather.observation_date
where
    trip_duration_minutes > 0
    and trip_distance > 0

