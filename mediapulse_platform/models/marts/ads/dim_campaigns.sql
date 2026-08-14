-- dim_campaigns: one row per AdConnect campaign.
-- The conformed campaign dimension for both projects - join fact tables to this
-- to get campaign attributes instead of repeating the lookup in every mart.

with campaigns as (

    select * from {{ ref('stg_ads__campaigns') }}

)

select
    campaign_id,
    campaign_name,
    campaign_type,
    advertiser_id,
    start_date,
    end_date,
    budget_cents / 100.0    as budget_dollars

from campaigns
