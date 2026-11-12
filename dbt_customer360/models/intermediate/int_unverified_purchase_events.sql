{{ config(
    materialized = 'table'
) }}

WITH invalid_purchase_events AS (

    SELECT
        transaction_id,
        user_pseudo_id,
        event_date,
        ga_session_id,
        event_timestamp,
        purchase_revenue_in_usd,

        CASE
            WHEN transaction_id IS NULL
                THEN 'null_transaction_id'
            WHEN TRIM(transaction_id) = ''
                THEN 'blank_transaction_id'
            WHEN transaction_id = '(not set)'
                THEN 'not_set_transaction_id'
        END AS invalid_id_reason

    FROM {{ ref('stg_ga4_events') }}

    WHERE event_name = 'purchase'
      AND (
          transaction_id IS NULL
          OR TRIM(transaction_id) = ''
          OR transaction_id = '(not set)'
      )

)

SELECT
    p.transaction_id,
    p.user_pseudo_id,
    i.customer_id,
    i.is_simulated AS identity_mapping_is_simulated,
    p.event_date,
    p.ga_session_id,
    p.event_timestamp,
    p.purchase_revenue_in_usd AS observed_revenue_usd,
    p.invalid_id_reason

FROM invalid_purchase_events p

INNER JOIN {{ ref('int_customer_identity_map') }} i
    ON p.user_pseudo_id = i.user_pseudo_id