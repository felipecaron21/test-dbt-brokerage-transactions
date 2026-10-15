WITH source AS (
    SELECT * FROM {{ ref('clients') }}
),

renamed AS (
    SELECT
        {{ clean_string('client_id') }} AS client_id,
        {{ clean_string('name') }} AS client_name,
        {{ clean_string('city') }} AS city,
        {{ clean_string('state', uppercase=true) }} AS state,
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