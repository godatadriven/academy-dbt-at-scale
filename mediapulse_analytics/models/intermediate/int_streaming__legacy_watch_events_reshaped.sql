with watch_events_new as (
    select * from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}
),
watch_events_legacy_reshaped as (
    select
        max(ping_id) as event_id,
        legacy_subscriber_id as user_id,
        legacy_content_id as content_id,
        concat(ping_date, ' ', max(ping_time)) as watched_at,
        max(playback_position_seconds) as watch_duration_seconds,
        min(device_code) as device_type,
        ping_date as batched_at
    from {{ ref('stg_streamview_legacy__watch_pings') }}
    group by legacy_subscriber_id, legacy_content_id, ping_date
)
select * from watch_events_new 
union all 
select * from watch_events_legacy_reshaped
