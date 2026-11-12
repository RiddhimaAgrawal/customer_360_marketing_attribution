{{ config(
    materialized = 'table'
) }}

WITH purchase_events AS (

    SELECT
        transaction_id,
        user_pseudo_id,
        event_date,
        ga_session_id,
        event_timestamp,
        purchase_revenue_in_usd

    FROM {{ ref('stg_ga4_events') }}

    WHERE event_name = 'purchase'
      AND transaction_id IS NOT NULL
      AND TRIM(transaction_id) != ''
      AND transaction_id != '(not set)'

),

ranked_purchases AS (

    SELECT
        transaction_id,
        user_pseudo_id,
        event_date,
        ga_session_id,
        event_timestamp,
        purchase_revenue_in_usd,

        COUNT(*) OVER (
            PARTITION BY
                transaction_id,
                user_pseudo_id,
                event_date,
                ga_session_id
        ) AS purchase_event_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                transaction_id,
                user_pseudo_id,
                event_date,
                ga_session_id
            ORDER BY event_timestamp ASC
        ) AS event_rank

    FROM purchase_events

)

SELECT
    transaction_id,
    user_pseudo_id,
    event_date,
    ga_session_id,
    event_timestamp AS order_timestamp,
    purchase_revenue_in_usd AS order_revenue_usd,
    purchase_event_count

FROM ranked_purchases

WHERE event_rank = 1