with source as (

    select * from {{ source('ads', 'spend') }}

),

renamed as (

    select
        spend_id,
        campaign_id,
        cast(spend_date as date)                        as spend_date,
        spend_cents / 100.0                             as spend_dollars,
        platform_fee_cents / 100.0                      as platform_fee_dollars,
        (spend_cents - platform_fee_cents) / 100.0      as net_spend_dollars

    from source

)

select * from renamed
