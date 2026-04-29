with 

source as (

    select * from {{ source('streaming', 'subscriptions') }}

),

renamed as (

    select
        subscription_id,
        user_id,
        trim(lower(plan_type)) as plan_type,
        trim(lower(status)) as subscription_status,
        start_date,
        start_time,
        cast(start_date || ' ' || start_time as timestamp) as started_at,
        end_date,
        end_time,
        cast(end_date || ' ' || end_time as timestamp) as ended_at,
        monthly_fee_cents / 100 as monthly_fee_dollars

    from source

)

select * from renamed