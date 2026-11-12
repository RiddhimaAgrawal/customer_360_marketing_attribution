SELECT *
FROM {{ ref('int_customer_identity_map') }}
WHERE is_simulated IS NOT TRUE