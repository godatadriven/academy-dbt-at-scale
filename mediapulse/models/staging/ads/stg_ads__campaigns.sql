with source as (

    select * from {{ source('ads', 'campaigns') }}

),

renamed as (

    select
        campaign_id,
        advertiser_id,
        campaign_name,
        lower(trim(campaign_type))      as campaign_type,
        cast(start_date as date)        as start_date,
        cast(end_date as date)          as end_date,
        budget_cents / 100.0            as budget_dollars

    from source

)

select * from renamed
