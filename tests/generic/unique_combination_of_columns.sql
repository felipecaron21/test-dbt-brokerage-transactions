{% test unique_combination_of_columns(model, combination_of_columns) %}

{%- set columns_csv = combination_of_columns | join(', ') -%}

SELECT
    {{ columns_csv }},
    COUNT(*) AS occurrences
FROM {{ model }}
GROUP BY {{ columns_csv }}
HAVING COUNT(*) > 1

{% endtest %}