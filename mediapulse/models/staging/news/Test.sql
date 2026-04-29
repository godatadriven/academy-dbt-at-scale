select
article_id,
count(*)
from {{ ref('stg_news__articles') }}
group by 1
order by 2 desc