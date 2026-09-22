with

    source as (

        select p.*, d.platform
        from {{ ref('stg_podcasts__listens') }} p
        left join {{ ref("platform_mapping") }} d using (platform_id)

    ),

    joined as (
        select 
            source.*, 
            e.show_id,
            e.duration_seconds as total_length_seconds
        from source
        left join {{ ref("stg_podcasts__episodes") }} e using (episode_id)
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
            platform,
            {{ safe_divide('listen_duration_seconds', 'total_length_seconds') }} as completion_rate

        from joined

    )

select *
from renamed