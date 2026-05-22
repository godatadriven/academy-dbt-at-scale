with spend as (
    select * from {{ ref('stg_ads__spend') }}
),

campaigns as (
    select * from {{ ref('stg_ads__campaigns') }}
),

commission_rate as (
    select * from {{ ref('commission_lookup') }}
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
        s.net_spend_dollars,
        r.commission_rate
    from 
        impressions i
        left join campaigns c on i.campaign_id = c.campaign_id
        left join spend s on s.campaign_id = i.campaign_id and s.spend_date = i.impression_date
        left join commission_rate r on r.campaign_type = c.campaign_type
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
        round(impressions_count / sum(impressions_count) over (partition by campaign_id, impression_date) * 100, 2) as impression_share,
        impression_share * spend_dollars as allocated_spend_dollars,
        impression_share * net_spend_dollars as allocated_net_spend_dollars,
        commission_rate,
        round(allocated_net_spend_dollars * commission_rate, 2) as mediapulse_revenue_dollars
        
    from enriched
)

select * from final