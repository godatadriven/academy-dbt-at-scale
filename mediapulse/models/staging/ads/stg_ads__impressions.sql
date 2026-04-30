with 
/*
Grain per impression_id
*/
source as (

    select * from {{ source('ads', 'impressions') }}

),

renamed as (

    select

        cast(impression_id as string) as impression_id,
        campaign_id,
        content_id,
        cast(impression_date as date) as impression_date,
        clicks / impressions_count as click_through_rate,
        impressions_count,
        clicks 
    
    from source
)

select * from renamed
