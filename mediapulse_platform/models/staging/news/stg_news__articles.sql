with source as (

    select * from {{ source('news', 'articles') }}

),

renamed as (

    select
        article_id,
        title                                as article_title,
        author_id,
        category,
        cast(published_at as timestamp)      as published_at,
        cast(updated_at   as timestamp)      as updated_at,
        status,
        word_count

    from source

)

select * from renamed
