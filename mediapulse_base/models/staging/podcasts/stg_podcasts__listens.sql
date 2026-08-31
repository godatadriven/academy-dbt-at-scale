with

    source as (

        select p.*, d.platform
        from {{ source("podcasts", "listens") }} p
        left join {{ ref("platform_mapping") }} d using (platform_id)

    ),

    joined as (
        select 
            source.*, 
            e.show_id,
            e.duration_seconds as total_length_seconds
        from source
        left join {{ source("podcasts", "episodes") }} e using (episode_id)
    ),

    renamed as (

        select
            listen_id,
            episode_id,
            show_id,
            user_id,
            listened_at,
            listen_duration_seconds,
            total_length_seconds,
            platform

        from joined

    )

select *
from renamed
