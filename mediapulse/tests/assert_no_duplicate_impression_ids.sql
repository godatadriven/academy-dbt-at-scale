select impression_id, count(*) as cnt
from {{ ref('fct_ad_impressions') }}
group by 1
having count(*) > 1
