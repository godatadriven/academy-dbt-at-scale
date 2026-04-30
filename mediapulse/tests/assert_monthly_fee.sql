select
    *
from
    {{ ref('stg_streaming__subscriptions') }}
where
    subscription_status != 'trialing'
    and monthly_fee_dollars = 0