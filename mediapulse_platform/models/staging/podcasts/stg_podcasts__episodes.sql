with
    source as (select * from {{ source("podcasts", "episodes") }}),

    renamed as (

        select
            -- add a surrogate key
            episode_id,
            show_id,
            title as episode_title,
            cast(published_at as timestamp) as published_at,
            duration_seconds,
            episode_season

        from source

    )

select *
from renamed
