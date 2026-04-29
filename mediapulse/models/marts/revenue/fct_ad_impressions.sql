{{ config(
      materialized='incremental',
      incremental_strategy='append',
) }}

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
    c.advertiser_id,
    c.campaign_type,
    c.campaign_name,
    c.start_date as campaign_start_date,
    c.end_date as campaign_end_date,
    c.budget_dollars as campaign_budget_dollars,
    i.impressions,
    i.clicks,
    i.ctr

    from impressions i
    left join campaigns c on i.campaign_id = c.campaign_id

