
{{ config(materialized = 'table') }}

WITH order_touchpoints AS (

    SELECT
        o.transaction_id,
        o.user_pseudo_id,
        o.event_date AS order_date,
        o.order_timestamp,
        o.order_revenue_usd,

        TO_HEX(
            SHA256(
                CONCAT(
                    o.transaction_id, '|',
                    o.user_pseudo_id, '|',
                    CAST(o.event_date AS STRING), '|',
                    CAST(o.ga_session_id AS STRING)
                )
            )
        ) AS order_key,

        t.touchpoint_id,
        t.touchpoint_date,
        t.touchpoint_timestamp,

        COALESCE(t.source, '(direct)') AS source,
        COALESCE(t.medium, '(none)') AS medium,
        COALESCE(t.campaign, '(not set)') AS campaign

    FROM {{ ref('int_orders') }} o

    LEFT JOIN {{ ref('int_marketing_touchpoints') }} t
        ON o.user_pseudo_id = t.user_pseudo_id
       AND t.touchpoint_timestamp <= o.order_timestamp

),

ranked_touchpoints AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY order_key
            ORDER BY touchpoint_timestamp ASC, touchpoint_id ASC
        ) AS first_touch_rank,

        ROW_NUMBER() OVER (
            PARTITION BY order_key
            ORDER BY touchpoint_timestamp DESC, touchpoint_id DESC
        ) AS last_touch_rank,

        COUNT(*) OVER (
            PARTITION BY order_key
        ) AS touchpoint_count,

        POWER(
            0.5,
            DATE_DIFF(
                order_date,
                COALESCE(touchpoint_date, order_date),
                DAY
            ) / 7.0
        ) AS time_decay_raw_weight

    FROM order_touchpoints

),

weighted_touchpoints AS (

    SELECT
        *,

        SUM(time_decay_raw_weight) OVER (
            PARTITION BY order_key
        ) AS total_time_decay_weight

    FROM ranked_touchpoints

)

SELECT
    order_key,
    transaction_id,
    user_pseudo_id,
    order_date,
    order_revenue_usd,

    touchpoint_id,
    touchpoint_date,

    source,
    medium,
    campaign,

    touchpoint_count,

    CASE
        WHEN first_touch_rank = 1
        THEN order_revenue_usd
        ELSE 0
    END AS first_touch_revenue,

    CASE
        WHEN last_touch_rank = 1
        THEN order_revenue_usd
        ELSE 0
    END AS last_touch_revenue,

    SAFE_DIVIDE(
        order_revenue_usd,
        touchpoint_count
    ) AS linear_attributed_revenue,

    SAFE_DIVIDE(
        order_revenue_usd * time_decay_raw_weight,
        total_time_decay_weight
    ) AS time_decay_attributed_revenue

FROM weighted_touchpoints
