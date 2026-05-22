{{
    config(
        materialized='incremental'
        , incremental_strategy='merge'
        , unique_key=['campaign_id', 'content_id', 'impression_date']
    )
}}

with impressions as (

    select 
        *
    from
        {{ ref('stg_ads__impressions') }}

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where impression_date >= dateadd('day', -3, (select max(impression_date) from {{ this }}))
    {% endif %}

)

, campaigns as (

    select
        *
    from
        {{ ref('stg_ads__campaigns') }}

)

, combined as (
    select 
        i.*
        , c.campaign_name
        , c.campaign_type
        , c.advertiser_id
    from
        impressions i
        left join campaigns c on i.campaign_id = c.campaign_id 
)

select * from combined

