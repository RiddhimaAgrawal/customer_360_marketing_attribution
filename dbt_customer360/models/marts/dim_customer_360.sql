
{{ config(materialized = 'table') }}

WITH customers AS (

    SELECT *
    FROM {{ ref('stg_crm_customers') }}

),

customer_activity AS (

    SELECT *
    FROM {{ ref('int_customer_session_activity') }}

),

customer_order_activity AS (

    SELECT *
    FROM {{ ref('int_customer_order_activity') }}

),

dataset_watermark AS (

    SELECT
        MAX(event_date) AS dataset_as_of_date
    FROM {{ ref('int_ga4_sessions') }}

)

SELECT
    -- Customer identity
    c.customer_id,
    c.first_name,
    c.last_name,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.country,
    c.customer_tier,
    c.signup_date,
    c.marketing_opt_in,

    -- Identity resolution
    COALESCE(a.linked_visitor_ids, 0) AS linked_visitor_ids,

    -- Engagement
    COALESCE(a.total_sessions, 0) AS total_sessions,
    COALESCE(a.total_events, 0) AS total_events,
    COALESCE(a.total_page_views, 0) AS total_page_views,
    COALESCE(a.active_days, 0) AS active_days,
    COALESCE(a.avg_events_per_session, 0)
        AS avg_events_per_session,

    -- GA4 purchase-event diagnostics
    COALESCE(a.total_purchase_events, 0)
        AS ga4_purchase_event_count,

    COALESCE(a.purchase_sessions, 0)
        AS ga4_purchase_sessions,

    COALESCE(a.purchase_event_revenue_usd, 0)
        AS ga4_purchase_event_revenue_usd,

    -- Verified order metrics
    COALESCE(o.verified_order_count, 0)
        AS verified_order_count,

    COALESCE(o.verified_purchase_sessions, 0)
        AS verified_purchase_sessions,

    COALESCE(o.verified_order_revenue_usd, 0)
        AS verified_order_revenue_usd,

    COALESCE(o.average_order_value_usd, 0)
        AS average_order_value_usd,

    o.first_purchase_date,
    o.last_purchase_date,

    COALESCE(o.verified_order_count, 0) > 0
        AS has_purchased,

    -- Activity dates
    a.first_activity_date,
    a.last_activity_date,

    w.dataset_as_of_date,

    CASE
        WHEN a.last_activity_date IS NOT NULL
        THEN DATE_DIFF(
            w.dataset_as_of_date,
            a.last_activity_date,
            DAY
        )
        ELSE NULL
    END AS last_activity_recency_days,

    -- Customer activity classification
    CASE
        WHEN COALESCE(a.total_sessions, 0) > 0
        THEN 'has_activity'
        ELSE 'no_activity'
    END AS activity_status,

    -- Data provenance
    TRUE AS identity_mapping_is_simulated

FROM customers c

LEFT JOIN customer_activity a
    ON c.customer_id = a.customer_id

LEFT JOIN customer_order_activity o
    ON c.customer_id = o.customer_id

CROSS JOIN dataset_watermark w
