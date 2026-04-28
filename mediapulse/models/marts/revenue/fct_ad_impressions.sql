{{
    config(
        materialized='incremental',
        incremental_strategy='append'
    )
}}

with impressions as (
    select * from {{ ref('stg_ads__impressions') }}
),

campaigns as (
    select
        campaign_id,
        campaign_type,
        advertiser_id
    from {{ ref('stg_ads__campaigns') }}
),

joined as (
    select
        i.impression_id,
        i.campaign_id,
        i.content_id,
        i.impression_date,
        i.impressions_count,
        i.clicks,
        i.click_through_rate,
        c.campaign_type,
        c.advertiser_id
    from impressions i
    left join campaigns c using (campaign_id)
)

select * from joined


{% if is_incremental() %}
    where impression_date > (select max(impression_date) from {{ this }})
{% endif %}
