with source as (

    select * from {{ source('ads', 'campaigns') }}

),

renamed as (

    select
        campaign_id,
        advertiser_id,
        upper(campaign_name) as campaign_name,
        campaign_type,
        start_date::date as start_date,
        end_date::date as end_date,
        budget_cents,
        {{ cents_to_dollars('budget_cents',2) }} as budget_dollars

    from source

)

select * from renamed
