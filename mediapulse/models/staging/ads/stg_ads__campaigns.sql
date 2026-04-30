with
/*
Grain per campaign_id
*/
source as (
    
    select * from {{ source('ads', 'campaigns') }}

),

renamed as (

    select

        campaign_id,
        advertiser_id,
        campaign_name,
        campaign_type,
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date,
        {{ cents_to_dollars('budget_cents') }} as budget_dollar
    
    from source
)

select * from renamed