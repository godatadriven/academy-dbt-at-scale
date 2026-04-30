select
    spend_id, spend_dollars, spend_date
from {{ ref('stg_ads__spend') }}
where spend_dollars < 0
    or platform_fee_dollars < 0