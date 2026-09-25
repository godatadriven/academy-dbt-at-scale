with 

source as (

    select * from {{ source('ads', 'campaigns') }}

),

renamed as (

    select
        campaign_id,
        advertiser_id,
        campaign_name,
        campaign_type,
        start_date,
        end_date,
        budget_cents

    from source

)

select * from renamed