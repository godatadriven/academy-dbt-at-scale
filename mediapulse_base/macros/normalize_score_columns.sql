{% macro normalize_score_columns(score_response_pairs) %}
    {% for (score, responses) in score_response_pairs %}
        case when trim({{score}}) in ('', 'N/A', '-1') then NULL else cast({{score}} as float) end as {{score}},
        case when trim({{responses}}) in ('', 'N/A', '-1') then NULL else cast({{responses}} as float) end as {{responses}}{%- if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}