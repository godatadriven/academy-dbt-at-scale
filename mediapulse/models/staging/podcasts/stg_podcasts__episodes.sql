with source as (

    select * from {{ source('podcasts', 'episodes') }}

),

renamed as (

    select
        episode_id,
        show_id,
        episode_name                         as episode_title,
        cast(published_at as timestamp)      as published_at,
        duration_seconds,
        season,
        episode_number

    from source

)

select * from renamed
