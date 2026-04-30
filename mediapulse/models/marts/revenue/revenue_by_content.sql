with spend as (
    select * from {{ ref('stg_ads__spend') }}
),

campaigns as (
    select * from {{ ref('stg_ads__campaigns') }}
),

impressions as (
    select
        campaign_id,
        campaign_type,
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
        i.campaign_type,
        s.spend_dollars,
        s.net_spend_dollars
    from impressions i
    inner join campaigns c
        using (campaign_id)
    inner join spend s
        on  i.campaign_id     = s.campaign_id
        and i.impression_date = s.spend_date
),

final as (
    select
        campaign_id,
        content_id,
        impression_date,
        impressions_count,
        campaign_type,
        spend_dollars,
        net_spend_dollars
    from enriched
)

select * from final