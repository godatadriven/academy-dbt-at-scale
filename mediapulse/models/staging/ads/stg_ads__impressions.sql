with source as (

    select * from {{ source('ads', 'impressions') }}

),

renamed as (

    select
        impression_id,
        campaign_id,
        content_id,
        impression_date,
        impressions_count as impressions,
        clicks,
        DIV0(clicks,impressions)::float as ctr

    from source

)

select * from renamed
