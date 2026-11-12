SELECT *
FROM {{ ref('stg_identity_links') }}
WHERE is_simulated IS NOT TRUE