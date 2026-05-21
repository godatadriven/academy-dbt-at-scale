with 

source as (

    select * from {{ source('ads', 'campaigns') }}

),

renamed as (

    select
        campaign_id,
        advertiser_id,
        campaign_name,
        {{ clean_string('campaign_type') }} as campaign_type,
        start_date::date as start_date,
        end_date::date as end_date,
        {{ cents_to_dollars('budget_cents') }}::numeric(16,2) as budget_dollars

    from source

)

select * from renamed