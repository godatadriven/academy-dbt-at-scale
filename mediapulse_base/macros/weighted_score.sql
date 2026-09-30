{% macro weighted_score(score_responses_rescale_factor_weighted) %}
    {% for (score, responses, rescale_factor, weighted) in score_responses_rescale_factor_weighted %}
        coalesce({{score}}, 0) * {{rescale_factor}} * coalesce({{responses}}, 0) as {{weighted}}{%- if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}