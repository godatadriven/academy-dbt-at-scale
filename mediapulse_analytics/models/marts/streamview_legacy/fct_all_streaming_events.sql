select *
from {{ ref('int_streamview_legacy__watch_pings')}}
where watched_at < '2024-01-01 00:21:00'

union all

select *
from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}