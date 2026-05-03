with source as (

    select * from {{ source('podcasts', 'episodes_updated') }}

),

renamed as (

    select
        episode_id,
        show_id,
        title,
        published_at,
        duration_seconds,
        season_episode,
        category

    from source

)

select * from renamed