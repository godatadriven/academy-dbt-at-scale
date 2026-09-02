-- fct_ad_impressions: one row per campaign/content impression record.

with impressions as (

    select * from {{ ref('stg_ads__impressions') }}

),

campaigns as (

    select
        campaign_id,
        campaign_type

    from {{ ref('stg_ads__campaigns') }}

)

select
    impressions.impression_id,
    impressions.campaign_id,
    campaigns.campaign_type,
    impressions.content_id,
    impressions.impression_date,
    impressions.impressions_count,
    impressions.clicks,
    -- case
    --     when impressions.impressions_count = 0 then 0
    --     else round(1.0 * impressions.clicks / impressions.impressions_count, 4)
    -- end    as click_through_rate
    {{safe_divide('impressions.clicks', 'impressions.impressions_count')}} as click_through_rate

from impressions
left join campaigns
    on impressions.campaign_id = campaigns.campaign_id
