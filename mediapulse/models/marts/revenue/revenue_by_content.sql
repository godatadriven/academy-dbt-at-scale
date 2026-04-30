-- MediaPulse revenue by content mart.
-- Show how ad revenue from AdConnect maps to individual content items
-- across the MediaPulse portfolio.
--
-- Status: work in progress - check the aggregation grain matches what consumers expect.

with spend as (

    select * from {{ ref('stg_ads__spend') }}

),

campaigns as (

    select * from {{ ref('stg_ads__campaigns') }}

),

impressions as (

    select * from {{ ref('fct_ad_impressions') }}

),

commission_lookup as (

 select * from {{ ref('commission_lookup') }}

),

enriched as (

    select

        i.campaign_id,
        i.content_id,
        i.impression_date,
        i.impressions_count,
        c.campaign_type,
        s.spend_dollars,
        s.platform_fee_dollars,
        s.net_spend_dollars

    from impressions as i
    inner join campaigns as c
        on i.campaign_id = c.campaign_id
    inner join spend as s
        on i.campaign_id = s.campaign_id
        and i.impression_date = s.spend_date

),

with_impression_share as (

    select

        *,
        impressions_count / nullif(
            sum(impressions_count) over (
                partition by campaign_id, impression_date
            ), 0
        ) as impression_share

    from enriched

),

allocated as (

    select

        *,
        impression_share * spend_dollars as allocated_spend_dollars,
        impression_share * net_spend_dollars as allocated_net_spend_dollars
    
    from with_impression_share
),

with_commission as (

    select

        a.*,
        cl.commission_rate,
        cl.commission_rate * a.net_spend_dollars as mediapulse_revenue_dollars

    from allocated as a
    left join commission_lookup as cl
        on a.campaign_type = cl.campaign_type

),

final as (

    select

        campaign_id,
        content_id,
        impression_date,
        impressions_count,
        campaign_type,
        spend_dollars,
        net_spend_dollars,
        impression_share,
        allocated_spend_dollars,
        allocated_net_spend_dollars,
        commission_rate,
        mediapulse_revenue_dollars
        
    from with_commission
)

select * from final
