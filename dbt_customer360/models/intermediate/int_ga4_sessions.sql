WITH valid_session_events AS (

    SELECT *
    FROM {{ ref('stg_ga4_events') }}
    WHERE user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL

),

session_metrics AS (

    SELECT
        user_pseudo_id,
        event_date,
        ga_session_id,

        MIN(event_timestamp) AS session_start_timestamp,
        MAX(event_timestamp) AS session_end_timestamp,

        COUNT(*) AS event_count,

        COUNTIF(event_name = 'page_view') AS page_view_count,

        COUNTIF(event_name = 'purchase') AS purchase_event_count,

        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN COALESCE(purchase_revenue_in_usd, 0)
                ELSE 0
            END
        ) AS purchase_revenue_usd

    FROM valid_session_events

    GROUP BY
        user_pseudo_id,
        event_date,
        ga_session_id

),

session_attribution AS (

    SELECT
        user_pseudo_id,
        event_date,
        ga_session_id,

        COUNT(
            DISTINCT IF(
                NULLIF(event_source, '(not set)') IS NOT NULL
                OR NULLIF(event_medium, '(not set)') IS NOT NULL
                OR NULLIF(event_campaign, '(not set)') IS NOT NULL,

                TO_JSON_STRING(
                    STRUCT(
                        event_source,
                        event_medium,
                        event_campaign
                    )
                ),

                NULL
            )
        ) AS attribution_variant_count,

        ARRAY_AGG(
            IF(
                NULLIF(event_source, '(not set)') IS NOT NULL
                OR NULLIF(event_medium, '(not set)') IS NOT NULL
                OR NULLIF(event_campaign, '(not set)') IS NOT NULL,

                STRUCT(
                    event_source,
                    event_medium,
                    event_campaign
                ),

                NULL
            )
            IGNORE NULLS
            ORDER BY event_timestamp
            LIMIT 1
        )[SAFE_OFFSET(0)] AS selected_attribution

    FROM valid_session_events

    GROUP BY
        user_pseudo_id,
        event_date,
        ga_session_id

)

SELECT

    TO_HEX(
        SHA256(
            CONCAT(
                m.user_pseudo_id,
                '|',
                CAST(m.event_date AS STRING),
                '|',
                CAST(m.ga_session_id AS STRING)
            )
        )
    ) AS session_key,

    m.user_pseudo_id,
    m.event_date,
    m.ga_session_id,

    m.session_start_timestamp,
    m.session_end_timestamp,

    TIMESTAMP_MICROS(m.session_start_timestamp)
        AS session_start_time_utc,

    TIMESTAMP_MICROS(m.session_end_timestamp)
        AS session_end_time_utc,

    m.event_count,
    m.page_view_count,
    m.purchase_event_count,
    m.purchase_revenue_usd,

    CASE
        WHEN a.selected_attribution IS NULL THEN 'direct'
        ELSE COALESCE(
            NULLIF(a.selected_attribution.event_source, '(not set)'),
            '(not set)'
        )
    END AS session_source,

    CASE
        WHEN a.selected_attribution IS NULL THEN '(none)'
        ELSE COALESCE(
            NULLIF(a.selected_attribution.event_medium, '(not set)'),
            '(not set)'
        )
    END AS session_medium,

    CASE
        WHEN a.selected_attribution IS NULL THEN '(not set)'
        ELSE COALESCE(
            NULLIF(a.selected_attribution.event_campaign, '(not set)'),
            '(not set)'
        )
    END AS session_campaign,

    COALESCE(a.attribution_variant_count, 0)
        AS attribution_variant_count,

    COALESCE(a.attribution_variant_count, 0) > 1
        AS has_attribution_conflict,

    a.selected_attribution IS NULL
        AS has_missing_attribution

FROM session_metrics m

LEFT JOIN session_attribution a
    ON m.user_pseudo_id = a.user_pseudo_id
    AND m.event_date = a.event_date
    AND m.ga_session_id = a.ga_session_id