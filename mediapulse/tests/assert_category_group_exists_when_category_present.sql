-- tests/assert_category_group_exists_when_category_present.sql
-- Fails if a category group is missing when teh category is there

with category_groups as (
    select 
        distinct category,
        category_group
    from {{ ref('content_performance') }}
)

select * from category_groups
where category is not null and category_group is null