with
/*
Grain per spend_id
*/
source as (

    select * from {{ source('ads', 'spend') }}

),

renamed as (

    select

        spend_id,
        campaign_id,
        cast(spend_date as date) as spend_date,
        {{ cents_to_dollars('spend_cents') }} as spend_dollars,
        {{ cents_to_dollars('platform_fee_cents') }} as platform_fee_dollars

    from source
),

enriched as (

    select

        *,
        spend_dollars - platform_fee_dollars as net_spend_dollars

    from renamed

)

select * from enriched
