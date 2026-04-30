select
    campaign_id::text as campaign_id,
    advertiser_id::text as advertiser_id,
    campaign_name::text as campaign_name,
    campaign_type::text as campaign_type,
    start_date::date as start_date,
    end_date::date as end_date,
    {{ cents_to_dollars('budget_cents') }} as budget_dollars
from {{ source('ads', 'campaigns') }}