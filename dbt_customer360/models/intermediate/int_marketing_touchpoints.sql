
{{ config(materialized = 'table') }}

WITH session_events AS (

    SELECT
        user_pseudo_id,
        ga_session_id,
        event_date,
        event_timestamp,
        event_source,
        event_medium,
        event_campaign

    FROM {{ ref('stg_ga4_events') }}

    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL

),

session_touchpoints AS (

    SELECT
        user_pseudo_id,
        ga_session_id,

        MIN(event_date) AS touchpoint_date,
        MIN(event_timestamp) AS touchpoint_timestamp,

        ARRAY_AGG(
            event_source IGNORE NULLS
            ORDER BY event_timestamp
            LIMIT 1
        )[SAFE_OFFSET(0)] AS event_source,

        ARRAY_AGG(
            event_medium IGNORE NULLS
            ORDER BY event_timestamp
            LIMIT 1
        )[SAFE_OFFSET(0)] AS event_medium,

        ARRAY_AGG(
            event_campaign IGNORE NULLS
            ORDER BY event_timestamp
            LIMIT 1
        )[SAFE_OFFSET(0)] AS event_campaign,

        COUNT(*) AS session_event_count

    FROM session_events

    GROUP BY
        user_pseudo_id,
        ga_session_id

)

SELECT
    TO_HEX(
        SHA256(
            CONCAT(
                user_pseudo_id,
                '|',
                CAST(ga_session_id AS STRING)
            )
        )
    ) AS touchpoint_id,

    user_pseudo_id,
    ga_session_id,
    touchpoint_date,
    touchpoint_timestamp,

    COALESCE(event_source, '(direct)') AS source,
    COALESCE(event_medium, '(none)') AS medium,
    COALESCE(event_campaign, '(not set)') AS campaign,

    session_event_count

FROM session_touchpoints
