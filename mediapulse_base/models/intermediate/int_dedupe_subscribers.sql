with subscription_events as (

    select * from {{ ref('stg_streaming__subscriptions_lifecycle_rec') }}

),

ranked_subscription_events as (

    select
        *
    from subscription_events
    qualify row_number() over (
            partition by user_id
            order by
                updated_at desc nulls last,
                subscription_started_at desc nulls last,
                subscription_id desc
        ) = 1

)

select
    *
from ranked_subscription_events