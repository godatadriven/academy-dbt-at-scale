with spend as (

    select
        campaign_id,
        sum(spend_cents) as total_spend_cents
    from {{ ref('stg_ads__spend') }}
    group by campaign_id

),

campaigns as (

    select
        campaign_id,
        campaign_type
    from {{ ref('stg_ads__campaigns') }}

),

impressions as (

    select
        campaign_id,
        content_id,
        impressions_count,
        clicks
    from {{ ref('stg_ads__impressions') }}

),

-- Performance campaign types (sponsored_content, podcast_ad) only attribute spend
-- to content that drove at least one click. Brand/awareness types attribute to all
-- content regardless of clicks. This affects the denominator, not just the numerator:
-- excluded content is removed from the total so the remaining items still sum to 100%.
eligible_impressions as (

    select
        i.campaign_id,
        i.content_id,
        i.impressions_count
    from impressions as i
    inner join campaigns as c on i.campaign_id = c.campaign_id
    where
        c.campaign_type not in ('sponsored_content', 'podcast_ad')
        or i.clicks > 0

),

impression_shares as (

    select
        campaign_id,
        content_id,
        impressions_count,
        sum(impressions_count) over (partition by campaign_id) as total_eligible_impressions
    from eligible_impressions

),

final as (

    select
        c.campaign_id,
        c.campaign_type,
        ei.content_id,
        s.total_spend_cents,
        ei.impressions_count,
        ei.total_eligible_impressions,
        case
            when ei.total_eligible_impressions = 0 then 0
            else round(
                1.0 * s.total_spend_cents * ei.impressions_count / ei.total_eligible_impressions
            )
        end                                                                    as allocated_spend_cents
    from impression_shares as ei
    inner join campaigns as c on ei.campaign_id = c.campaign_id
    inner join spend as s on ei.campaign_id = s.campaign_id

)

select * from final
