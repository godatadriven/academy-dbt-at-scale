-- models/intermediate/int_news__articles_deduped.sql

with articles as (

    select * from {{ ref('stg_news__articles') }}

),

-- Some articles appear more than once: an edit to an article (status change,
-- word count update, a previously-missing survey score backfilled) produces
-- a new row with the same article_id but a later updated_at, rather than
-- overwriting the original row in place. We only want the most recent
-- version of each article going forward.

ranked as (

    select
        articles.*,
        row_number() over (
            partition by article_id
            order by updated_at desc
        ) as version_rank

    from articles

),

final as (

    select
        article_id,
        title,
        author_id,
        category,
        status,
        published_at,
        updated_at,
        word_count,
        score_relevance,
        score_clarity,
        score_bias,
        score_trust,
        score_engagement,
        num_responses_relevance,
        num_responses_clarity,
        num_responses_bias,
        num_responses_trust,
        num_responses_engagement

    from ranked
    where version_rank = 1

)

select * from final