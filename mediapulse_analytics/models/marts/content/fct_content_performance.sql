-- fct_content_performance: MediaPulse unified content performance fact.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.

with articles as (

    select
        article_id          as content_id,
        title       as content_title,
        category,
        published_at,
        'news'              as platform,
        max(word_count)          as content_length_units,
        null::int           as duration_seconds

    from {{ ref('mediapulse_base', 'stg_news__articles') }}
    group by 1,2,3,4,5,7

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
    group by 1,2,3,4,6,7

),

combined as (

    select
        content_id,
        content_title,
        category,
        published_at,
        platform,
        content_length_units,
        duration_seconds

    from articles

    union all

    select
        content_id,
        content_title,
        category,
        published_at,
        platform,
        content_length_units,
        duration_seconds

    from episodes

)

select * from combined
