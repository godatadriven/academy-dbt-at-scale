select campaign_id, content_id, impression_date, count(*) as cnt
from {{ ref('stg_ads__impressions') }}
group by all
having count(*) > 1
