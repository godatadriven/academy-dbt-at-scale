with listens as (

    select * from {{ ref('stg_podcasts__listens') }}

),

episodes as (

    select
        episode_id,
        show_id,
        duration_seconds as total_length_seconds

    from {{ ref('stg_podcasts__episodes') }}

),

platforms as (

    select
        platform_id,
        platform

    from {{ ref('platform_mapping') }}

),

enriched as (

    select
        listens.listen_id,
        listens.episode_id,
        episodes.show_id,
        listens.user_id,
        listens.listened_at,
        listens.listen_duration_seconds,
        episodes.total_length_seconds,
        platforms.platform

    from listens
    left join episodes
        on listens.episode_id = episodes.episode_id
    left join platforms
        on listens.platform_id = platforms.platform_id

)

select * from enriched
