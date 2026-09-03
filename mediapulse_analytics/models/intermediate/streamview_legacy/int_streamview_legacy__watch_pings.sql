-- Watch events
-- New version
-- select * --One row per playback event
-- from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}
-- -- where user_id = 'usr_109' and content_id = 'cnt_052'
-- where user_id = 'usr_671' and content_id = 'cnt_111' -- two rows on same watched_at date

-- -- Legacy
-- select * --One row per ping, recorded roughly once per minute of playback.
-- from {{ ref('stg_streamview_legacy__watch_pings')}}
-- where legacy_subscriber_id = 'SV100011'



select
    legacy_subscriber_id || legacy_content_id || ping_date as event_id
    , legacy_subscriber_id as user_id
    , legacy_content_id as content_id
    , timestamp_from_parts(ping_date::date, min(ping_time::time)) as watched_at
    , timestampdiff(second, min(ping_time::time), max(ping_time::time)) as watch_duration_seconds
    , mode(device_code) as device_type
    , null as batched_at
from {{ ref('stg_streamview_legacy__watch_pings')}}
group by legacy_subscriber_id, legacy_content_id, ping_date




