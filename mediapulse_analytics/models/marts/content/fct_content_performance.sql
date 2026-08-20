-- fct_content_performance: MediaPulse unified content performance fact.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.

with articles as (

    select
        article_id          as content_id,
        article_title       as content_title,
        category,
        published_at,
        'news'              as platform,
        word_count          as content_length_units,
        null::int           as duration_seconds

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

    select
        a.content_id,
        a.content_title,
        a.category,
        a.published_at,
        a.platform,
        a.content_length_units,
        a.duration_seconds

    from articles a
    inner join episodes e
        on a.category = e.category

)

select * from combined
