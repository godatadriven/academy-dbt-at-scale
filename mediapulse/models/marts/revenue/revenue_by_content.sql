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

enriched as (

    select
        i.campaign_id,
        i.content_id,
        i.impression_date,
        i.campaign_name,
        i.impressions,
        i.campaign_type,
        s.spend_dollars,
        s.spend_dollars - s.platform_fee_dollars      as net_spend_dollars,
        DIV0(i.impressions, sum(i.impressions) over (partition by i.campaign_id, i.impression_date)) as impression_share

    from impressions i
    inner join spend s 
        on s.campaign_id = i.campaign_id
        and s.spend_date = i.impression_date
),

final as (
    select e.*,
        e.impression_share * e.spend_dollars as allocated_spend_dollars,
        e.impression_share * e.net_spend_dollars as allocated_net_spend_dollars,
        cl.commission_rate,
        (allocated_net_spend_dollars * cl.commission_rate) as mediapulse_revenue_dollars
    from enriched e
    left join {{ ref('commission_lookup') }} cl using (campaign_type)
)

select  
    campaign_id,
    content_id,
    impression_date,
    impressions,
    campaign_type,
    spend_dollars,
    net_spend_dollars,
    impression_share,
    allocated_spend_dollars,
    allocated_net_spend_dollars,
    commission_rate,
    mediapulse_revenue_dollars
from final
