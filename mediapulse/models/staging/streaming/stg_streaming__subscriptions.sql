with 

source as (

    select * from {{ source('streaming', 'subscriptions') }}

),

renamed as (

    select
        subscription_id,
        user_id,
        {{ clean_string('plan_type') }} as plan_type,
        {{ clean_string('status') }} as subscription_status,
        start_date,
        start_time,
        cast(start_date || ' ' || start_time as timestamp) as started_at,
        end_date,
        end_time,
        cast(end_date || ' ' || end_time as timestamp) as ended_at,
        {{ cents_to_dollars('monthly_fee_cents') }} as monthly_fee_dollars

    from source

)

select * from renamed