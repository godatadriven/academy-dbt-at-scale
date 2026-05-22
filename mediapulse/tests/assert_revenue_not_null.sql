select 
    *
from
    {{ ref('revenue_by_content') }}
where mediapulse_revenue_dollars is null