{{ config(severity='warn') }}

SELECT
    client_id,
    client_name,
    asset_ticker,
    bought_quantity,
    sold_quantity,
    net_quantity
FROM {{ ref('mart_client_portfolio') }}
WHERE net_quantity < 0