{% test assert_category_group(model, column_name, category_group_table, category_group_column)%}

select 
    m.{{ column_name }}
from 
    {{ model }} m
    left join {{ category_group_table}} map
    on m.{{column_name}} = map.{{category_group_column}}
where 
    m.{{ column_name }} is not null
    and map.{{category_group_column}} is null

{% endtest %}