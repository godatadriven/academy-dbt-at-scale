-- models/staging/stg_news__articles.sql

with source as (

    select * from {{ source('news', 'articles') }}

),

renamed as (

    select
        article_id,
        title,
        author_id,
        published_at::timestamp as published_at,
        updated_at::timestamp   as updated_at,
        word_count::int         as word_count,

        -- category and status arrive with inconsistent casing, whitespace,
        -- and outright synonyms (e.g. 'tech' vs 'technology', 'live' vs
        -- 'published') - normalize both to a fixed canonical set below

        trim(lower(category)) as category_raw,
        trim(lower(status))   as status_raw,

        -- score/response columns are passed through as-is here; sentinel
        -- values (blank strings, 'N/A', -1) and rescaling are handled
        -- further downstream, not in staging

        score_relevance,
        score_clarity,
        score_bias,
        score_trust,
        score_engagement,

        num_responses_relevance,
        num_responses_clarity,
        num_responses_bias,
        num_responses_trust,
        num_responses_engagement,

    from source

),

normalized as (

    select
        article_id,
        title,
        author_id,
        published_at,
        updated_at,
        word_count,

        case
            when category_raw in ('politics') then 'politics'
            when category_raw in ('technology', 'tech') then 'technology'
            when category_raw in ('entertainment', 'showbiz') then 'entertainment'
            when category_raw in ('sport', 'sports') then 'sport'
            else 'unknown'
        end as category,

        case
            when status_raw in ('published', 'live') then 'published'
            when status_raw in ('draft', 'new') then 'draft'
            when status_raw in ('archived', 'removed') then 'archived'
            else 'unknown'
        end as status,

        case when trim(score_relevance) in ('', 'N/A', '-1') then NULL else cast(score_relevance as float) end as score_relevance,
        case when trim(score_clarity) in ('', 'N/A', '-1') then NULL else cast(score_clarity as float) end as score_clarity,
        case when trim(score_bias) in ('', 'N/A', '-1') then NULL else cast(score_bias as float) end as score_bias,
        case when trim(score_trust) in ('', 'N/A', '-1') then NULL else cast(score_trust as float) end as score_trust,
        case when trim(score_engagement) in ('', 'N/A', '-1') then NULL else cast(score_engagement as float) end as score_engagement,

        case when trim(num_responses_relevance) in ('', 'N/A', '-1') then NULL else cast(num_responses_relevance as float) end as num_responses_relevance,
        case when trim(num_responses_clarity) in ('', 'N/A', '-1') then NULL else cast(num_responses_clarity as float) end as num_responses_clarity,
        case when trim(num_responses_bias) in ('', 'N/A', '-1') then NULL else cast(num_responses_bias as float) end as num_responses_bias,
        case when trim(num_responses_trust) in ('', 'N/A', '-1') then NULL else cast(num_responses_trust as float) end as num_responses_trust,
        case when trim(num_responses_engagement) in ('', 'N/A', '-1') then NULL else cast(num_responses_engagement as float) end as num_responses_engagement

    from renamed

)

select * from normalized