with
    articles as (select * from {{ ref("stg_news__articles") }}),

    -- Each score dimension needs three things before it can be summed:
    -- 1. rescale onto a common 0-10 basis (score_bias is 1-5, score_trust is 0-100)
    -- 2. coalesce missing scores/response counts to 0 so they don't null out the
    -- whole sum
    -- 3. multiply the rescaled score by its response count, so dimensions with
    -- more survey responses carry more weight in the total
    scored as (

        select
            article_id,
            title,
            author_id,
            category,
            status,
            published_at,

            -- relevance: already 0-10, no rescale needed
            coalesce(score_relevance, 0)
            * coalesce(num_responses_relevance, 0) as weighted_relevance,

            -- clarity: already 0-10, no rescale needed
            coalesce(score_clarity, 0)
            * coalesce(num_responses_clarity, 0) as weighted_clarity,

            -- bias: scale is 1-5, rescale to 0-10 by multiplying by 2
            coalesce(score_bias, 0)
            * 2
            * coalesce(num_responses_bias, 0) as weighted_bias,

            -- trust: scale is 0-100, rescale to 0-10 by dividing by 10
            (coalesce(score_trust, 0) / 10.0)
            * coalesce(num_responses_trust, 0) as weighted_trust,

            -- engagement: already 0-10, but may not exist for older articles
            -- (survey dimension added mid-year) - coalesce handles that gracefully
            coalesce(score_engagement, 0)
            * coalesce(num_responses_engagement, 0) as weighted_engagement,

            coalesce(num_responses_relevance, 0)
            + coalesce(num_responses_clarity, 0)
            + coalesce(num_responses_bias, 0)
            + coalesce(num_responses_trust, 0)
            + coalesce(num_responses_engagement, 0) as total_responses

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

            weighted_relevance
            + weighted_clarity
            + weighted_bias
            + weighted_trust
            + weighted_engagement as total_weighted_score,

            total_responses,

            -- per-response average, useful for comparing articles
            -- fairly regardless of how many survey responses they each got
            round(
                (
                    weighted_relevance
                    + weighted_clarity
                    + weighted_bias
                    + weighted_trust
                    + weighted_engagement
                )
                / nullif(total_responses, 0),
                2
            ) as weighted_avg_score

        from scored

    )

select *
from final
