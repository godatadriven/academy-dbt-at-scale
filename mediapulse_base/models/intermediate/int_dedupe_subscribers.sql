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

Save

12345678910111213141516171819202122232425262728293031





dbt Wizard
Commands
Results
Code quality
Co$0

)

select
    subscription_id,
    user_id,
    plan_type,
    status,
    subscription_started_at,
    end_date,
    end_time,
    monthly_fee_cents,
    updated_at

from ranked_subscription_events