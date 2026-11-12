WITH customer_visitors AS (

    SELECT
        customer_id,
        user_pseudo_id

    FROM {{ ref('int_customer_identity_map') }}

),

customer_orders AS (

    SELECT
        cv.customer_id,
        o.transaction_id,
        o.event_date,
        o.ga_session_id,
        o.order_timestamp,
        o.order_revenue_usd

    FROM customer_visitors cv

    INNER JOIN {{ ref('int_orders') }} o
        ON cv.user_pseudo_id = o.user_pseudo_id

)

SELECT
    customer_id,

    COUNT(order_timestamp) AS verified_order_count,

    COUNT(DISTINCT ga_session_id)
        AS verified_purchase_sessions,

    SUM(order_revenue_usd)
        AS verified_order_revenue_usd,

    MIN(event_date) AS first_purchase_date,

    MAX(event_date) AS last_purchase_date,

    AVG(order_revenue_usd) AS average_order_value_usd

FROM customer_orders

GROUP BY customer_id