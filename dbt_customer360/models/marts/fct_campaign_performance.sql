{{ config(materialized = 'table') }}

WITH attributed_campaigns AS (
    SELECT
        source,
        medium,
        campaign,
        COUNT(DISTINCT order_key) AS attributed_orders,
        SUM(first_touch_revenue) AS first_touch_revenue_usd,
        SUM(last_touch_revenue) AS last_touch_revenue_usd,
        SUM(linear_attributed_revenue) AS linear_attributed_revenue_usd,
        SUM(time_decay_attributed_revenue) AS time_decay_attributed_revenue_usd
    FROM {{ ref('fct_order_attribution') }}
    GROUP BY source, medium, campaign
),

campaign_metrics AS (
    SELECT
        a.*,
        s.spend_usd,
        s.spend_type
    FROM attributed_campaigns a
    LEFT JOIN {{ ref('campaign_spend') }} s
        ON a.source = s.source
       AND a.medium = s.medium
       AND a.campaign = s.campaign
)

SELECT
    source,
    medium,
    campaign,
    attributed_orders,
    first_touch_revenue_usd,
    last_touch_revenue_usd,
    linear_attributed_revenue_usd,
    time_decay_attributed_revenue_usd,
    spend_usd,
    spend_type,

    SAFE_DIVIDE(linear_attributed_revenue_usd, spend_usd)
        AS linear_roas,

    SAFE_DIVIDE(
        linear_attributed_revenue_usd - spend_usd,
        spend_usd
    ) * 100 AS linear_roi_pct,

    SAFE_DIVIDE(spend_usd, attributed_orders)
        AS cost_per_attributed_order_usd,

    SAFE_DIVIDE(first_touch_revenue_usd, spend_usd)
        AS first_touch_roas,

    SAFE_DIVIDE(last_touch_revenue_usd, spend_usd)
        AS last_touch_roas,

    SAFE_DIVIDE(time_decay_attributed_revenue_usd, spend_usd)
        AS time_decay_roas

FROM campaign_metrics