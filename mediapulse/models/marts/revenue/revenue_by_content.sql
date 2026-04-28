with spend as (
    select * from {{ ref('stg_ads__spend') }}
),

campaigns as (
    select * from {{ ref('stg_ads__campaigns') }}
),

impressions as (
    select
        campaign_id,
        content_id,
        impression_date,
        impressions_count
    from {{ ref('fct_ad_impressions') }}
),

enriched as (
    select
        i.campaign_id,
        i.content_id,
        i.impression_date,
        i.impressions_count,
        c.campaign_type,
        s.spend_dollars,
        s.net_spend_dollars
    from impressions i
    inner join campaigns c
        using (campaign_id)
    inner join spend s
        on  i.campaign_id    = s.campaign_id
        and i.impression_date = s.spend_date
),

with_share as (
    select
        *,
        impressions_count
            / nullif(sum(impressions_count) over (
                partition by campaign_id, impression_date
            ), 0) as impression_share
    from enriched
),

allocated as (
    select
        *,
        impression_share * spend_dollars     as allocated_spend_dollars,
        impression_share * net_spend_dollars as allocated_net_spend_dollars
    from with_share
),

with_commission as (
    select
        a.*,
        cl.commission_rate,
        a.allocated_net_spend_dollars * cl.commission_rate as mediapulse_revenue_dollars
    from allocated a
    left join {{ ref('commission_lookup') }} cl using (campaign_type)
)

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