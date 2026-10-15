WITH clients AS (
    SELECT * FROM {{ ref('stg_clients') }}
)

SELECT
    client_id,
    client_name,
    city,
    state,
    created_at
FROM clients