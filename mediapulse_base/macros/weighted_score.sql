-- This macro calculates weighted scores:
-- The score is rescaled to a range of 0 to 10 by multiplying it with a factor.
-- Next it is multiplied with the number of responses and stored as a weighted variable
-- The macro takes a list of 
--  (score_column, number_of_responses_column, rescale_factor, weighted_output_column) quadruples as argument

{% macro weighted_score(score_responses_rescale_factor_weighted) %}
    {% for (score, responses, rescale_factor, weighted) in score_responses_rescale_factor_weighted %}
        coalesce({{score}}, 0) * {{rescale_factor}} * coalesce({{responses}}, 0) as {{weighted}}{%- if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}