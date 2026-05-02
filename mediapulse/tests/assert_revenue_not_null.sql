{{ config(store_failures = true) }}

select
    campaign_id,
    mediapulse_revenue_dollars
from {{ ref('revenue_by_content') }}
having mediapulse_revenue_dollars < 0