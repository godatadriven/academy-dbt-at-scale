with source as (

with source as (
    select * from {{ source('news', 'articles') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by article_id 
            order by updated_at desc
        ) as rn
    from source
)

select
    article_id,
    title,
    author_id,
    created_at,
    updated_at
from deduplicated
where rn = 1