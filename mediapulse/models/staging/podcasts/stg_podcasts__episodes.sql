with source as (

    select * from {{ source('podcasts', 'episodes') }}

),

renamed as (

    select 
        episode_id,
        show_id,
        title as episode_title,
        cast(published_at as timestamp) as published_at,
        duration_seconds,
        season_episode,
        split_part(season_episode, '-', 2)::int as season_number,
        split_part(season_episode, '-', 1)::int as episode_number,

    from source

)

select * from renamed