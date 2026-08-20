with source as (

    select * from {{ source('streaming', 'subscriptions_lifecycle_rec') }}

),

renamed as (

    select distinct
        subscription_id,
        user_id,
        plan_type,
        status,
        start_date,
        start_time,
        coalesce(
            try_to_timestamp_ntz(
                start_date || ' ' || coalesce(nullif(start_time, ''), '00:00:00'),
                'YYYY-MM-DD HH24:MI:SS'
            ),
            try_to_timestamp_ntz(
                start_date || ' ' || coalesce(nullif(start_time, ''), '00:00:00'),
                'YYYY-DD-MM HH24:MI:SS'
            )
        ) as subscription_started_at,
        end_date,
        end_time,
        cast(nullif(monthly_fee_cents, 'N/A') as integer) as monthly_fee_cents,
        try_to_timestamp_ntz(cast(updated_at as varchar)) as updated_at

    from source

)

select * from renamed