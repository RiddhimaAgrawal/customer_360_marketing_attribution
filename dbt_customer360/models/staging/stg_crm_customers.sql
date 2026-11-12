SELECT
    TRIM(customer_id) AS customer_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    LOWER(TRIM(email)) AS email,
    SAFE_CAST(signup_date AS DATE) AS signup_date,
    TRIM(country) AS country,
    TRIM(customer_tier) AS customer_tier,
    marketing_opt_in

FROM {{ source('synthetic_crm', 'crm_customers') }}