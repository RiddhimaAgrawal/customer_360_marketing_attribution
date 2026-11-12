
{{ config(materialized = 'table') }}

WITH customer_base AS (

    SELECT
        customer_id,
        customer_name,
        email,
        country,
        customer_tier,
        signup_date,
        marketing_opt_in,
        verified_order_count,
        verified_order_revenue_usd,
        average_order_value_usd,
        first_purchase_date,
        last_purchase_date,
        dataset_as_of_date

    FROM {{ ref('dim_customer_360') }}

),

rfm_base AS (

    SELECT
        *,

        DATE_DIFF(
            dataset_as_of_date,
            last_purchase_date,
            DAY
        ) AS recency_days

    FROM customer_base

    WHERE verified_order_count > 0

),

rfm_scores AS (

    SELECT
        *,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        CASE
            WHEN verified_order_count >= 5 THEN 5
            WHEN verified_order_count >= 3 THEN 4
            WHEN verified_order_count >= 2 THEN 3
            ELSE 1
        END AS frequency_score,

        NTILE(5) OVER (
            ORDER BY verified_order_revenue_usd ASC
        ) AS monetary_score

    FROM rfm_base

),

rfm_segments AS (

    SELECT
        *,

        CONCAT(
            CAST(recency_score AS STRING),
            CAST(frequency_score AS STRING),
            CAST(monetary_score AS STRING)
        ) AS rfm_score,

        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'

            WHEN recency_score >= 3
                 AND frequency_score >= 3
                THEN 'Loyal Customers'

            WHEN recency_score >= 4
                 AND monetary_score >= 4
                THEN 'Potential High Value'

            WHEN recency_score <= 2
                 AND frequency_score >= 2
                THEN 'At Risk'

            WHEN recency_score >= 4
                 AND frequency_score <= 2
                THEN 'Recent Customers'

            WHEN recency_score <= 2
                 AND frequency_score <= 2
                THEN 'Needs Attention'

            ELSE 'Regular Customers'
        END AS customer_segment

    FROM rfm_scores

)

SELECT
    c.customer_id,
    c.customer_name,
    c.email,
    c.country,
    c.customer_tier,
    c.marketing_opt_in,

    COALESCE(c.verified_order_count, 0)
        AS frequency,

    COALESCE(c.verified_order_revenue_usd, 0)
        AS monetary_value_usd,

    c.average_order_value_usd,

    c.first_purchase_date,
    c.last_purchase_date,

    DATE_DIFF(
        c.dataset_as_of_date,
        c.last_purchase_date,
        DAY
    ) AS recency_days,

    r.recency_score,
    r.frequency_score,
    r.monetary_score,
    r.rfm_score,

    COALESCE(
        r.customer_segment,
        'No Verified Purchase'
    ) AS customer_segment

FROM customer_base c

LEFT JOIN rfm_segments r
    ON c.customer_id = r.customer_id
