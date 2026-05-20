{{ config(severity = 'warn') }}

select 
    p.category,
    map.category_group
from 
    {{ ref('content_performance') }} p
    left join {{ ref('category_mapping') }} map
    on p.category = map.category_group
where 
    p.category is not null
    and map.category_group is null