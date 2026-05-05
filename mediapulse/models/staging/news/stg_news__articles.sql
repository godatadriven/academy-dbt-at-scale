with source as (

    select * from {{ source('news', 'articles') }}

),

deduped as (
    select
        *,
        max(updated_at) over (partition by article_id) as article_last_updated_at
    from source
),

renamed as (

    select
        article_id,
        title                                as article_title,
        author_id,
        {{ clean_string('category') }}       as category,
        cast(published_at as timestamp)      as published_at,
        cast(updated_at   as timestamp)      as updated_at,
        {{ clean_string('status') }}         as status,
        word_count,
        
    from deduped
    where article_last_updated_at = updated_at

)

select * from renamed
