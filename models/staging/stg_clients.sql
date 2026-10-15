WITH source AS (
    SELECT * FROM {{ ref('clients') }}
),

renamed AS (
    SELECT
        NULLIF(TRIM(client_id), '') AS client_id,
        TRIM(name) AS client_name,
        NULLIF(TRIM(city), '') AS city,
        UPPER(TRIM(state)) AS state,
        CAST(created_at AS DATE) AS created_at
    FROM source
),

deduplicated AS (
    SELECT *
        FROM renamed
        WHERE client_id IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY client_id
            ORDER BY (city IS NULL), created_at
        ) = 1
)

SELECT * FROM deduplicated