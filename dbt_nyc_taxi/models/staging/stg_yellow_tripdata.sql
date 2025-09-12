with source_data as (

    select * from {{ source('raw_data','yellow_tripdata') }}

),

deduplicated_data as (

    select
        *,
        row_number() over(partition by vendorid, tpep_pickup_datetime, tpep_dropoff_datetime, fare_amount, trip_distance, total_amount, tip_amount order by tpep_pickup_datetime) as row_num
    from source_data

)

select

    {{ dbt_utils.generate_surrogate_key(['vendorid', 'tpep_pickup_datetime', 'tpep_dropoff_datetime', 'fare_amount', 'trip_distance', 'total_amount', 'tip_amount']) }} as tripid,

    cast(vendorid as integer) as vendor_id,


    coalesce(cast(ratecodeid as integer), 0) as ratecode_id,

    cast(pulocationid as integer) as pickup_location_id,
    cast(dolocationid as integer) as dropoff_location_id,


    cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,


    store_and_fwd_flag,


    coalesce(cast(passenger_count as integer), 0) as passenger_count,

    cast(trip_distance as numeric) as trip_distance,


    cast(payment_type as integer) as payment_type,
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount

from deduplicated_data

where

    row_num = 1

    and fare_amount >= 0
    and total_amount >= 0
