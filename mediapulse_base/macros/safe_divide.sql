-- macro to do a safe divide. Takes 3 arguments: numerator, denominator and precision
-- if the denominator is zero, a zero is returned alse the numerator is divided by denominator
-- the result of the division is returned rounded to 4 digits after the comma.
-- This can be controlled by the precision argument.


{% macro safe_divide(numerator, denominator, precision=4) %}
    case
        when {{ denominator }} = 0
        then 0
        else least(round(1.0 * {{ numerator }} / {{ denominator }}, {{ precision }}), 1)
    end
{% endmacro %}
