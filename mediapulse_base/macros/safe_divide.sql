{% macro safe_divide(numerator, denominator, precision=4) %}
    case
        when {{ denominator }} = 0
        then 0
        else least(round(1.0 * {{ numerator }} / {{ denominator }}, {{ precision }}), 1)
    end
{% endmacro %}
