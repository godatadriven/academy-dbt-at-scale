select
    impression_id::text as impression_id,
    campaign_id::text as campaign_id,
    content_id::text as content_id,
    impression_date::date as impression_date,
    impressions_count::numeric as impressions_count,
    clicks::int as clicks,
    case 
        when impressions_count = 0 then 0
        else clicks / impressions_count
    end as click_through_rate
from {{ source('ads', 'impressions') }}