select spend_id, spend_date, spend_dollars
from {{ ref('stg_ads__spend') }}
where spend_dollars < 0
   or net_spend_dollars < 0
