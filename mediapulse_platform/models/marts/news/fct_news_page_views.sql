-- fct_news_page_views: one row per article page view event.

with page_views as (

    select * from {{ ref('stg_news__page_views') }}

),

articles as (

    select
        article_id,
        category,
        author_id

    from {{ ref('stg_news__articles') }}
    qualify row_number() over (partition by article_id order by updated_at desc) = 1

)

select
    page_views.view_id,
    page_views.article_id,
    articles.category,
    articles.author_id,
    page_views.user_id,
    page_views.viewed_at,
    page_views.referrer_source

from page_views
left join articles
    on page_views.article_id = articles.article_id
