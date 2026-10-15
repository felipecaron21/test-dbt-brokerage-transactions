WITH source AS (
    SELECT * FROM {{ ref('transactions') }}
),

renamed AS (
    SELECT
        {{ clean_string('transaction_id') }} AS transaction_id,
        {{ clean_string('client_id') }} AS client_id,
        {{ clean_string('asset_ticker', uppercase=true) }} AS asset_ticker,
        {{ clean_string('operation', uppercase=true) }} AS operation,
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