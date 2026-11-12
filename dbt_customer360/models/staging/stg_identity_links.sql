SELECT
    TRIM(customer_id) AS customer_id,
    TRIM(user_pseudo_id) AS user_pseudo_id,
    TRIM(link_method) AS link_method,
    is_simulated

FROM {{ source('synthetic_crm', 'identity_links') }}