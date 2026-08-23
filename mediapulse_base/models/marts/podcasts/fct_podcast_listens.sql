-- fct_podcast_listens: one row per podcast listen session.

with listens as (

    select * from {{ ref('stg_podcasts__listens') }}

),

episodes as (

    select
        episode_id,
        show_id,
        duration_seconds

    from {{ ref('stg_podcasts__episodes') }}

)

select
    listens.listen_id,
    listens.episode_id,
    episodes.show_id,
    listens.user_id,
    listens.listened_at,
    listens.listen_duration_seconds,
    least(1.0 * listens.listen_duration_seconds / nullif(episodes.duration_seconds, 0), 1.0)    as completion_rate,
    listens.platform

from listens
left join episodes
    on listens.episode_id = episodes.episode_id
