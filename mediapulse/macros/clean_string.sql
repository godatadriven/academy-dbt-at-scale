{% macro clean_string(column_name) %}
    coalesce(lower(trim({{ column_name }})), '')
{% endmacro %}