-- dim_shows: one row per PodcastHub show, with episode output stats.

with shows as (

    select * from {{ ref('int_shows_clean_string_columns') }}

),

episodes as (

    select
        show_id,
        count(*)                as total_episodes,
        min(cast(published_at as timestamp))       as first_episode_at,
        max(cast(published_at as timestamp))       as most_recent_episode_at

    from {{ ref('stg_podcasts__episodes') }}
    group by show_id

)

select
    shows.show_id,
    shows.show_name,
    shows.host_name,
    shows.category,
    shows.launched_at,
    coalesce(episodes.total_episodes, 0)    as total_episodes,
    episodes.first_episode_at,
    episodes.most_recent_episode_at

from shows
left join episodes
    on shows.show_id = episodes.show_id
