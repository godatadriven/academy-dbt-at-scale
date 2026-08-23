with source as (

    select * from {{ source('news', 'page_views') }}

),

renamed as (

    select
        view_id,
        article_id,
        user_id,
        cast(viewed_at as timestamp)    as viewed_at,
        referrer_source

    from source

)

select * from renamed
