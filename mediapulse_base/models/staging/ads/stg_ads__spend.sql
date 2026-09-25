with 

source as (

    select * from {{ source('ads', 'spend') }}

),

renamed as (

    select
        spend_id,
        campaign_id,
        spend_date,
        spend_cents,
        platform_fee_cents

    from source

)

select * from renamed