with source as (

    select * from {{ source('ads', 'impressions') }}

),

renamed as (

    select
        impression_id,
        campaign_id,
        content_id,
        cast(impression_date as date)                               as impression_date,
        impressions_count,
        clicks,
        case
            when impressions_count > 0
                then round(clicks / cast(impressions_count as float), 4)
            else 0
        end                                                         as click_through_rate

    from source

)

select * from renamed