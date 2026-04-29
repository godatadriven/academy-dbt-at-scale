-- MediaPulse unified content performance mart.
-- Intended to combine NewsNow articles and PodcastHub episodes into a single
-- content catalogue enriched with category metadata.
--
-- Status: work in progress - review the join logic before using downstream.

with articles as (

    select
        article_id          as content_id,
        article_title       as content_title,
        category,
        published_at,
        'news'              as platform,
        word_count          as content_length_units,
        null::int           as duration_seconds

    from {{ ref('stg_news__articles') }}

),

episodes as (

    select
        episode_id          as content_id,
        episode_title       as content_title,
        s.category          as category,
        published_at,
        'podcasts'          as platform,
        null::int           as content_length_units,
        duration_seconds
    from {{ ref('stg_podcasts__episodes') }} e
    left join {{ ref('stg_podcasts__shows') }} s on e.show_id = s.show_id

),

combined as (

select * from articles
union all
select * from episodes

)

select 
c.content_id,
c.content_title,
c.category,
c.published_at,
c.platform,
c.content_length_units,
c.duration_seconds,
coalesce(m.category_group, 'other') as category_group     
from combined c
left join {{ ref('category_mapping') }} m on c.category = m.category
