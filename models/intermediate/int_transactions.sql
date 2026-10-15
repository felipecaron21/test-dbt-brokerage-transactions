WITH transactions AS (
    SELECT * FROM {{ ref('stg_transactions') }}
),

clients AS (
    SELECT * FROM {{ ref('stg_clients') }}
),

enriched AS (
    SELECT
        t.transaction_id,
        t.transaction_date,
        t.client_id,
        c.client_name,
        c.city AS client_city,
        c.state AS client_state,
        t.asset_ticker,
        t.operation,
        t.quantity,
        t.unit_price,
        t.quantity * t.unit_price AS gross_amount,
        CASE
            WHEN t.operation = 'BUY' THEN t.quantity
            ELSE -t.quantity
        END AS signed_quantity,
        CASE
            WHEN t.operation = 'BUY' THEN t.quantity * t.unit_price
            ELSE -(t.quantity * t.unit_price)
        END AS signed_amount
    FROM transactions AS t
    LEFT JOIN clients AS c
        ON t.client_id = c.client_id
)

SELECT * FROM enriched