-- dim_subscriptions: one row per streaming subscription, with lifecycle timestamps
-- and current status. plan_type and status are lowercased to normalise the mixed
-- casing present in the raw subscriptions table.

with subscriptions as (

    select * from {{ ref('int_dedupe_subscribers') }}

)

select
    subscription_id,
    user_id,
    lower(plan_type)          as plan_type,
    lower(status)             as status,
    
    subscription_started_at,
    case
        when end_date is not null then
            try_to_timestamp_ntz(
                end_date || ' ' || coalesce(nullif(end_time, ''), '23:59:59')
            )
    end                       as subscription_ended_at,
    monthly_fee_cents / 100.0    as monthly_fee_dollars

from subscriptions
