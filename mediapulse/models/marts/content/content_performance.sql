-- MediaPulse unified content performance mart.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.
--
-- Status: completed

with articles as ( 
    select 
        article_id as content_id, 
        article_title as content_title, 
        published_at, 
        category,
        'news' as platform, 
        word_count as content_length_units, -- words for articles null as duration_seconds 
    from {{ ref('stg_news__articles') }} 
),

episodes as (
    select 
        episode_id          as content_id,
        episode_title       as content_title,
        published_at,
        -- note: podcasts category comes from shows join — simplified here
        category,
        'podcasts'          as platform,
        duration_seconds    as content_length_units,
    from {{ ref('stg_podcasts__episodes') }}
),

combined as (
    select * from articles
    union all
    select * from episodes
)
,

with_category as (
    select
        {{ dbt_utils.generate_surrogate_key(['content_id', 'platform']) }} as content_id_sk,
        c.*,
        cm.category_group
    from combined c
    left join {{ ref('category_mapping') }} cm
        using (category)
)

select * from with_category