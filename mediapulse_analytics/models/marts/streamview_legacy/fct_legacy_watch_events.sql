-- fct_legacy_watch_events: one row per StreamView (legacy) playback heartbeat
-- ping, enriched with mapped MediaPulse ids where the subscriber and content
-- have been migrated.

with pings as (

    select * from {{ ref('stg_streamview_legacy__watch_pings') }}

),

subscribers as (

    select
        legacy_subscriber_id,
        mapped_user_id

    from {{ ref('dim_legacy_subscribers') }}

),

content as (

    select
        legacy_content_id,
        mapped_content_id

    from {{ ref('dim_legacy_content') }}

)

select
    pings.ping_id,
    pings.legacy_subscriber_id,
    subscribers.mapped_user_id,
    pings.legacy_content_id,
    content.mapped_content_id,
    try_to_timestamp_ntz(pings.ping_date || ' ' || pings.ping_time)    as pinged_at,
    pings.playback_position_seconds,
    pings.device_code

from pings
left join subscribers
    on pings.legacy_subscriber_id = subscribers.legacy_subscriber_id
left join content
    on pings.legacy_content_id = content.legacy_content_id
