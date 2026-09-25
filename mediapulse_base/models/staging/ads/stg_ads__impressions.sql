with 

source as (

    select * from {{ source('ads', 'impressions') }}

),

renamed as (

    select
        impression_id,
        campaign_id,
        content_id,
        impression_date,
        impressions_count,
        clicks

    from source

)

select * from renamed