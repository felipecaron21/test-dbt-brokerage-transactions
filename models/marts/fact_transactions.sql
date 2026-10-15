{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='delete+insert',
        on_schema_change='fail'
    )
}}

WITH transactions AS (
    SELECT * FROM {{ ref('int_transactions') }}

    {% if is_incremental() %}
    WHERE transaction_date >= (SELECT MAX(transaction_date) FROM {{ this }})
    {% endif %}
)

SELECT
    transaction_id,
    transaction_date,
    client_id,
    asset_ticker,
    operation,
    quantity,
    unit_price,
    gross_amount,
    signed_quantity,
    signed_amount
FROM transactions