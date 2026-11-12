WITH customer_visitors AS (

    SELECT
        customer_id,
        user_pseudo_id

    FROM {{ ref('int_customer_identity_map') }}

),

customer_sessions AS (

    SELECT
        cv.customer_id,

        s.session_key,
        s.user_pseudo_id,
        s.event_date,
        s.event_count,
        s.page_view_count,
        s.purchase_event_count,
        s.purchase_revenue_usd

    FROM customer_visitors cv

    LEFT JOIN {{ ref('int_ga4_sessions') }} s
        ON cv.user_pseudo_id = s.user_pseudo_id

)

SELECT
    customer_id,

    COUNT(DISTINCT user_pseudo_id) AS linked_visitor_ids,

    COUNT(session_key) AS total_sessions,

    COALESCE(SUM(event_count), 0) AS total_events,

    COALESCE(SUM(page_view_count), 0) AS total_page_views,

    COALESCE(SUM(purchase_event_count), 0)
        AS total_purchase_events,

    COUNTIF(purchase_event_count > 0)
        AS purchase_sessions,

    COALESCE(SUM(purchase_revenue_usd), 0)
        AS purchase_event_revenue_usd,

    COUNT(DISTINCT event_date) AS active_days,

    MIN(event_date) AS first_activity_date,

    MAX(event_date) AS last_activity_date,

    COALESCE(
        SAFE_DIVIDE(
            SUM(event_count),
            COUNT(session_key)
        ),
        0
    ) AS avg_events_per_session

FROM customer_sessions

GROUP BY customer_id