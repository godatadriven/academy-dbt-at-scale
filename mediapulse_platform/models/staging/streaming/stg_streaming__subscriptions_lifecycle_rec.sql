with 

source as (

    select * from {{ source('streaming', 'subscriptions_lifecycle_rec') }}

),

renamed as (

    select
        subscription_id,
        user_id,
        plan_type,
        status,
        start_date,
        start_time,
        end_date,
        end_time,
        monthly_fee_cents

    from source

)

select * from renamed