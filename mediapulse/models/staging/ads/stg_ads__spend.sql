with source as (

    select * from {{ source('ads', 'spend') }}

),

renamed as (

    select
        spend_id,
        campaign_id,
        spend_date,
        spend_cents,
        {{ cents_to_dollars('spend_cents',2) }} as spend_dollars,
        platform_fee_cents,
        {{ cents_to_dollars('platform_fee_cents',2) }} as platform_fee_dollars,
        spend_dollars - platform_fee_dollars as net_spend_dollars

    from source

)

select * from renamed
