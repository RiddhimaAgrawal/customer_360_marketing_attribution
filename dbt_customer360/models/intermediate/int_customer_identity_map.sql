WITH identity_links AS (

    SELECT *
    FROM {{ ref('stg_identity_links') }}

),

customers AS (

    SELECT *
    FROM {{ ref('stg_crm_customers') }}

)

SELECT
    TO_HEX(
        SHA256(
            CONCAT(
                l.customer_id,
                '|',
                l.user_pseudo_id
            )
        )
    ) AS identity_map_key,

    l.customer_id,
    l.user_pseudo_id,

    c.first_name,
    c.last_name,
    c.email,
    c.signup_date,
    c.country,
    c.customer_tier,
    c.marketing_opt_in,

    l.link_method,
    l.is_simulated,

    c.customer_id IS NOT NULL AS is_customer_match_valid

FROM identity_links l

LEFT JOIN customers c
    ON l.customer_id = c.customer_id