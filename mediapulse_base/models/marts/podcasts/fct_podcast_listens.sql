-- fct_podcast_listens: one row per podcast listen session.
with listens as (select * from {{ ref("stg_podcasts__listens") }})

select
    listen_id,
    episode_id,
    show_id,
    user_id,
    listened_at,
    listen_duration_seconds,
    {{ calculate_completion_rate("listen_duration_seconds", "total_length_seconds") }} as completion_rate,
    platform

from listens
