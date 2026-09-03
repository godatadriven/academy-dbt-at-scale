(select * from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }})
union all
(select
    ping_id, legacy_subscriber_id, legacy_content_id, watched_at, playback_position_seconds, device_code, null as batched_at
from {{ ref("stg_streamview_legacy__watch_pings") }})