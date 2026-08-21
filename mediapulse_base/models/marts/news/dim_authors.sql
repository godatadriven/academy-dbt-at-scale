-- dim_authors: one row per NewsNow author, with article output stats.

with authors as (

    select * from {{ ref('stg_news__authors') }}

),

articles as (

    select
        author_id,
        count(*)                as total_articles,
        min(published_at)       as first_published_at,
        max(published_at)       as most_recent_published_at

    from {{ ref('stg_news__articles') }}
    group by author_id

)

select
    authors.author_id,
    authors.author_name,
    authors.email,
    authors.joined_at,
    coalesce(articles.total_articles, 0)    as total_articles,
    articles.first_published_at,
    articles.most_recent_published_at

from authors
left join articles
    on authors.author_id = articles.author_id
