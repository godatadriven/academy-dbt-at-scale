{% macro safe_divide(numerator, denominator, precision=4) %}
    
    case
        when {{denominator}} = 0
        then 0
        else round(1.0 * {{numerator}} / {{denominator}}, {{precision}})
    end

{% endmacro %}