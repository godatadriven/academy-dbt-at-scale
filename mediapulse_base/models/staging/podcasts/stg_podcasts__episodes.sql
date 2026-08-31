with source as (

    select * from {{ source('podcasts', 'episodes') }}

),

renamed as (

    select 
        episode_id,
        show_id,
        title as episode_title,
        published_at,
        duration_seconds,
        episode_season,
        category

    from source

)

select * from renamed

