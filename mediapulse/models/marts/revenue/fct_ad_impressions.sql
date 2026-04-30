
{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append'
  )
}}

with impressions as (
    select * from {{ ref('stg_ads__impressions') }}
    {% if is_incremental() %}
        where impression_date > (select max(impression_date) from {{ this }})
    {% endif %}
),
campaigns as (
    select * from {{ ref('stg_ads__campaigns') }}
)

select
    i.impression_id,
    i.campaign_id,
    i.content_id,
    i.impression_date,
    i.impressions_count,
    i.clicks,
    i.click_through_rate,
    c.advertiser_id,
    c.campaign_name,
    c.campaign_type,
    c.start_date,
    c.end_date,
    c.budget_dollars
from impressions i 
left join campaigns c 
    on i.campaign_id = c.campaign_id
where i.impression_date between c.start_date and c.end_date