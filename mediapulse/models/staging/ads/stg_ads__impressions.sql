with 

source as (

    select * from {{ source('ads', 'impressions') }}

),

renamed as (

    select
        impression_id,
        campaign_id,
        content_id,
        impression_date::date as impression_date,
        coalesce(impressions_count, 0) as impressions_count,
        coalesce(clicks, 0) as clicks,
        round(iff(impressions_count > 0, clicks / impressions_count, 0) * 100, 2) as click_through_rate

    from source

)

select * from renamed