-- fct_podcast_listens: one row per podcast listen session.

with listens as (

    select * from {{ ref('stg_podcasts__listens') }}

)

select
    listen_id,
    episode_id,
    show_id,
    user_id,
    listened_at,
    listen_duration_seconds,
    least(1.0 * listen_duration_seconds / nullif(total_length_seconds, 0), 1.0)    as completion_rate,
    platform

from listens
