with source as (

    select * from {{ source('news', 'articles') }}

),

renamed as (

    select
        article_id,
        title                                                               as article_title,
        author_id,
        category,
        cast(published_at as timestamp)                                     as published_at,
        cast(updated_at   as timestamp)                                     as updated_at,
        status,
        word_count,
        row_number() over (partition by article_id order by updated_at desc) as row_num

    from source
)

select * from renamed
where row_num = 1

