with

source as (

    select * from {{ source('ads', 'spend') }}

),

renamed as (

    select

        spend_id,
        campaign_id,
        cast(spend_date as date) as spend_date,
        {{ cents_to_dollars('spend_cents') }} as spend,
        {{ cents_to_dollars('platform_fee_cents') }} as platform_fee

    from source
)

select * from renamed
