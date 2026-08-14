with
    source as (select * from {{ source("podcasts", "episodes") }}),

    renamed as (

        select
            -- add a surrogate key
            episode_number_id,
            show_number_id,
            title as episode_title,
            cast(published_at as timestamp) as published_at,
            duration,
            episode_season

        from source

    )

select *
from renamed
