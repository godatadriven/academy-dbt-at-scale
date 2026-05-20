-- MediaPulse unified content performance mart.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.
--
-- Status: work in progress - review the join logic before using downstream.

with articles as (

    select
        article_id          as content_id,
        article_title       as content_title,
        category            as raw_category,
        published_at,
        'news'              as platform,
        word_count          as content_length_units,
        null::int           as duration_seconds

    from {{ ref('stg_news__articles') }}

),

episodes as (

    select
        e.episode_id                   as content_id,
        e.episode_title                as content_title,
        {{clean_string('s.category')}} as raw_category,
        e.published_at,
        'podcasts'                     as platform,
        null::int                      as content_length_units,
        e.duration_seconds

    from {{ ref('stg_podcasts__episodes') }} e
    left join {{ ref('stg_podcasts__shows') }} s
        on e.show_id = s.show_id

),

combined as (

    select * from articles
    union all 
    select * from episodes

),

with_category as (

    select
        c.content_id,
        c.content_title,
        coalesce(map.category_group, c.raw_category) as category,
        c.published_at,
        c.platform,
        c.content_length_units,
        c.duration_seconds

    from 
        combined c
        left join {{ ref('category_mapping') }} map
            on c.raw_category = map.category

)

select * from with_category
