WITH transactions AS (
    SELECT * FROM {{ ref('fact_transactions') }}
),

clients AS (
    SELECT * FROM {{ ref('dim_clients') }}
),

positions AS (
    SELECT
        client_id,
        asset_ticker,
        SUM(CASE WHEN operation = 'BUY' THEN quantity ELSE 0 END) AS bought_quantity,
        SUM(CASE WHEN operation = 'SELL' THEN quantity ELSE 0 END) AS sold_quantity,
        SUM(signed_quantity) AS net_quantity,
        SUM(CASE WHEN operation = 'BUY' THEN gross_amount ELSE 0 END) AS bought_amount,
        SUM(CASE WHEN operation = 'SELL' THEN gross_amount ELSE 0 END) AS sold_amount,
        SUM(signed_amount) AS net_amount,
        MAX(transaction_date) AS last_transaction_date
    FROM transactions
    GROUP BY client_id, asset_ticker
)

SELECT
    p.client_id,
    c.client_name,
    p.asset_ticker,
    p.bought_quantity,
    p.sold_quantity,
    p.net_quantity,
    p.bought_amount,
    p.sold_amount,
    p.net_amount,
    p.last_transaction_date
FROM positions AS p
LEFT JOIN clients AS c
    ON p.client_id = c.client_id