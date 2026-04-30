select
    spend_id::text as spend_id,
    campaign_id::text as campaign_id,
    spend_date::date as spend_date,
    {{ cents_to_dollars('spend_cents') }} as spend_dollars,
    {{ cents_to_dollars('platform_fee_cents') }} as platform_fee_dollars,
    (spend_dollars - platform_fee_dollars) as net_spend_dollars
from {{ source('ads', 'spend') }}