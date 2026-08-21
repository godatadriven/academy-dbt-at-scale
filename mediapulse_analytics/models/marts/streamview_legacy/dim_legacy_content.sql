-- dim_legacy_content: one row per StreamView (legacy) catalog item, resolved to
-- a current MediaPulse content_id where a mapping exists in
-- map_streaming_legacy_fields. Not every legacy item has been migrated yet.

with content as (

    select * from {{ ref('stg_streamview_legacy__content') }}

),

id_map as (

    select
        legacy_id,
        mediapulse_id

    from {{ ref('map_streaming_legacy_fields') }}
    where mapping_type = 'content_id'

)

select
    content.legacy_content_id,
    content.content_title,
    content.category,
    content.content_format,
    content.release_date,
    content.duration_minutes,
    id_map.mediapulse_id                as mapped_content_id,
    id_map.mediapulse_id is not null    as is_mapped

from content
left join id_map
    on content.legacy_content_id = id_map.legacy_id
