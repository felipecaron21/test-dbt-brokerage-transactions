WITH source AS (
    SELECT * FROM {{ ref('transactions') }}
),

renamed AS (
    SELECT
        NULLIF(TRIM(transaction_id), '') AS transaction_id,
        NULLIF(TRIM(client_id), '') AS client_id,
        UPPER(TRIM(asset_ticker)) AS asset_ticker,
        UPPER(TRIM(operation)) AS operation,
        CAST(quantity AS INTEGER) AS quantity,
        CAST(unit_price AS DECIMAL(18, 2)) AS unit_price,
        CAST(transaction_date AS DATE) AS transaction_date
    FROM source
)

SELECT *
    FROM renamed
    WHERE client_id IS NOT NULL
        AND quantity > 0
        AND unit_price > 0
        AND operation IN ('BUY', 'SELL')