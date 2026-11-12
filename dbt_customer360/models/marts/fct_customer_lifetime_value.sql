
{{ config(materialized = 'table') }}

WITH customer_metrics AS (

    SELECT
        customer_id,
        customer_name,
        country,
        customer_tier,
        verified_order_count,
        verified_order_revenue_usd,
        average_order_value_usd,
        first_purchase_date,
        last_purchase_date,
        dataset_as_of_date

    FROM {{ ref('dim_customer_360') }}

)

SELECT
    customer_id,
    customer_name,
    country,
    customer_tier,

    verified_order_count,
    verified_order_revenue_usd,
    average_order_value_usd,

    first_purchase_date,
    last_purchase_date,

    CASE
        WHEN verified_order_count > 0
        THEN DATE_DIFF(
            last_purchase_date,
            first_purchase_date,
            DAY
        )
        ELSE NULL
    END AS customer_lifespan_days,

    SAFE_DIVIDE(
        verified_order_revenue_usd,
        verified_order_count
    ) AS historical_revenue_per_order,

    SAFE_DIVIDE(
        verified_order_revenue_usd,
        NULLIF(
            DATE_DIFF(
                dataset_as_of_date,
                first_purchase_date,
                DAY
            ) + 1,
            0
        )
    ) AS historical_revenue_per_day,

    CASE
        WHEN verified_order_count > 0
        THEN 'Purchasing Customer'
        ELSE 'No Verified Purchase'
    END AS customer_value_status

FROM customer_metrics

