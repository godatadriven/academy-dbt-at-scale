-- fct_content_performance: MediaPulse unified content performance fact.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.

with articles as (

    select
        article_id          as content_id,
        title       as content_title,
        published_at,
        'news'              as platform,
        word_count          as content_length_units,
        null::int           as duration_seconds,
        category

    from {{ ref('mediapulse_base', 'stg_news__articles') }}

),

episodes as (

    select
        episode_id          as content_id,
        episode_title       as content_title,
        published_at,
        'podcasts'          as platform,
        null::int           as content_length_units,
        duration_seconds,
        category

    from {{ ref('mediapulse_base', 'stg_podcasts__episodes') }}

),

combined as (

    select * from articles
    union all
    select * from episodes    


)

select * from combined
