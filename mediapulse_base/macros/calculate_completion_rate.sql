{% macro calculate_completion_rate(listen_duration, total_length) -%}
    case
        when {{ total_length }} = 0 then 0
        else round(1.0 * {{ listen_duration }} / {{ total_length }}, 4)
    end
{%- endmacro %}
