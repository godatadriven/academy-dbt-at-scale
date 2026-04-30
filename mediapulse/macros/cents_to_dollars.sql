{% macro cents_to_dollars(column) %}
    ({{ column }} / 100.0)::numeric(16, 2)
{% endmacro %}