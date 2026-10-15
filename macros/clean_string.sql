{% macro clean_string(column_name, uppercase=false) %}
    {%- if uppercase -%}
        NULLIF(UPPER(TRIM({{ column_name }})), '')
    {%- else -%}
        NULLIF(TRIM({{ column_name }}), '')
    {%- endif -%}
{% endmacro %}