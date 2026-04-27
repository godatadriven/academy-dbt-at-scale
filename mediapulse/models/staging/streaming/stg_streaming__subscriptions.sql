with

    source as (select * from {{ source("streaming", "subscriptions") }}),

    renamed as (

        select
            subscription_id,
            user_id,
            {{ clean_string('plan_type') }} as plan_type,
            {{ clean_string('status') }} as subscription_status,
            cast(start_date || ' ' || start_time as timestamp) as started_at,
            cast(end_date || ' ' || end_time as timestamp) as ended_at,
            monthly_fee_cents / 100.0 as monthly_fee_dollars,

        from source

    )

select *
from renamed
