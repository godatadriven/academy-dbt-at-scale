with source as (

    select * from {{ source('podcasts', 'episodes') }}

),

renamed as (

    select 
        episode_id,
        show_id,
        episode_name as episode_title,
        cast(published_at as timestamp) as published_at,
        duration_seconds,
        cast(episode_number as varchar)
            || '-' ||
        cast(season as varchar) as season_episode

    from source

)

select * from renamed