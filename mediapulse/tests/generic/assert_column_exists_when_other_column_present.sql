-- tests/assert_column_exists_when_other_column_present.sql
-- Fails if a category group is missing when teh category is there

{% test assert_column_exists_when_other_column_present(model, column_name, other_column) %}

with deduped as (
    select 
        distinct {{ other_column }},
        {{ column_name }}
    from {{ model }}
)

select * from deduped
where {{ other_column }} is not null and {{ column_name }} is null

{% endtest %}