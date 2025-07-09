CREATE TABLE IF NOT EXISTS "raw".yellow_tripdata (
    vendorid                BIGINT,
    tpep_pickup_datetime    TIMESTAMP,
    tpep_dropoff_datetime   TIMESTAMP,
    passenger_count         BIGINT,
    trip_distance           DOUBLE PRECISION,
    ratecodeid              BIGINT,
    store_and_fwd_flag      VARCHAR(1),
    pulocationid            BIGINT,
    dolocationid            BIGINT,
    payment_type            BIGINT,
    fare_amount             DOUBLE PRECISION,
    extra                   DOUBLE PRECISION,
    mta_tax                 DOUBLE PRECISION,
    tip_amount              DOUBLE PRECISION,
    tolls_amount            DOUBLE PRECISION,
    improvement_surcharge   DOUBLE PRECISION,
    total_amount            DOUBLE PRECISION,
    congestion_surcharge    DOUBLE PRECISION,
    airport_fee             DOUBLE PRECISION
);


