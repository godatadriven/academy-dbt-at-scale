{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        unique_key='impression_id'
    )
}}

with 

impressions as (

    select * from {{ ref('stg_ads__impressions') }}

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where impression_date > (select max(impression_date) from {{ this }}) 
    {% endif %}

),

campaigns as (

    select * from {{ ref('stg_ads__campaigns') }}

),

final as (

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
    join campaigns c using (campaign_id)

)

select * from final