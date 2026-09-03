-- fct_podcast_listens: one row per podcast listen session.
with listens as (select * from {{ ref('int__podcasts_listens_enriched') }})


select
    listen_id,
    episode_id,
    show_id,
    user_id,
    listened_at,
    listen_duration_seconds,
    case
        when total_length_seconds = 0
        then 0
        else round(1.0 * listen_duration_seconds / total_length_seconds, 4)
    end as completion_rate,
    platform

from listens
