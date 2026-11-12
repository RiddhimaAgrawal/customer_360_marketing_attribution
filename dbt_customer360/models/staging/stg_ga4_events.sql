WITH source_events AS (

    SELECT
        event_date,
        event_timestamp,
        event_name,
        user_pseudo_id,
        user_id,

        -- Extract GA4 session information
        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS ga_session_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_number'
        ) AS ga_session_number,

        -- Extract event-level traffic attribution
        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'source'
        ) AS event_source,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'medium'
        ) AS event_medium,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'campaign'
        ) AS event_campaign,

        ecommerce.transaction_id,
        ecommerce.purchase_revenue_in_usd,
        ecommerce.total_item_quantity

    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

)

SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_timestamp,
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp_utc,
    event_name,
    user_pseudo_id,
    user_id,
    ga_session_id,
    ga_session_number,
    event_source,
    event_medium,
    event_campaign,
    transaction_id,
    purchase_revenue_in_usd,
    total_item_quantity

FROM source_events