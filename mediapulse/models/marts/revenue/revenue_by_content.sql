-- MediaPulse revenue by content mart.
-- Intended to show how ad revenue from AdConnect maps to individual content items
-- across the MediaPulse portfolio.
--
-- Status: work in progress — check the aggregation grain matches what consumers expect.

with spend as (

    select * from {{ ref('stg_ads__spend') }}

),

campaigns as (

    select * from {{ ref('stg_ads__campaigns') }}

),

campaign_revenue as (

    select
        c.campaign_id,
        c.campaign_name,
        c.campaign_type,
        c.advertiser_id,
        sum(s.spend_dollars)          as total_spend_dollars,
        sum(s.net_spend_dollars)      as total_net_spend_dollars,
        min(s.spend_date)             as first_spend_date,
        max(s.spend_date)             as last_spend_date

    from spend s
    inner join campaigns c using (campaign_id)
    group by 1, 2, 3, 4

)

select * from campaign_revenue
