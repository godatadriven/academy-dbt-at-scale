{% macro cents_to_dollars(column, decimals=2) %}
    ({{ column }} / 100.0)::numeric(16, {{ decimals }})
{% endmacro %}