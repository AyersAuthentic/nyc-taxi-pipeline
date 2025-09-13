WITH fct_trips AS (
    SELECT * FROM {{ ref('fct_trips') }}
),


precipitation_categories AS (
    SELECT
        *,
        CASE

            WHEN precipitation IS NULL OR precipitation = 0 THEN 'No Rain'

            WHEN precipitation > 0 AND precipitation <= 0.1 THEN 'Light Rain'

            WHEN precipitation > 0.1 AND precipitation <= 0.3 THEN 'Moderate Rain'

            WHEN precipitation > 0.3 THEN 'Heavy Rain'
        END AS precipitation_category
    FROM fct_trips
)

SELECT
    EXTRACT(YEAR FROM pickup_datetime) AS trip_year,
    EXTRACT(MONTH FROM pickup_datetime) AS trip_month,

    pickup_borough,
    dropoff_borough,
    precipitation_category,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY trip_duration_minutes) AS median_trip_duration,
    COUNT(tripid) AS trip_count
FROM precipitation_categories
GROUP BY
    trip_year,
    trip_month,
    pickup_borough,
    dropoff_borough,
    precipitation_category
