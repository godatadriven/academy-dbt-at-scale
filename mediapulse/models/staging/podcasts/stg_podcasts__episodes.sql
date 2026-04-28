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
        SPLIT_PART(season_episode, '-', 2) AS season,
        SPLIT_PART(season_episode, '-', 1) AS episode,
        category

    from source

)

select * from renamed