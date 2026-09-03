with pings as (

    select
        ping_id,
        legacy_subscriber_id,
        legacy_content_id,
        try_to_timestamp_ntz(ping_date || ' ' || ping_time) as pinged_at,
        playback_position_seconds,
        device_code

    from {{ ref('stg_streamview_legacy__watch_pings') }}

),

ordered_pings as (

    select
        *,
        lag(playback_position_seconds) over (
            partition by legacy_subscriber_id, legacy_content_id
            order by pinged_at, ping_id
        ) as previous_playback_position_seconds

    from pings

),

event_starts as (

    select
        *,
        previous_playback_position_seconds is null
            or playback_position_seconds <= previous_playback_position_seconds as is_event_start

    from ordered_pings

),

sessionized as (

    select
        *,
        sum(is_event_start::integer) over (
            partition by legacy_subscriber_id, legacy_content_id
            order by pinged_at, ping_id
            rows between unbounded preceding and current row
        ) as event_number

    from event_starts

),

watch_events as (

    select
        min_by(ping_id, pinged_at) as event_id,
        legacy_subscriber_id,
        legacy_content_id,
        min(pinged_at) as watched_at,
        max(playback_position_seconds) as watch_duration_seconds,
        min_by(device_code, pinged_at) as device_type

    from sessionized
    group by
        legacy_subscriber_id,
        legacy_content_id,
        event_number

),

id_map as (

    select
        mapping_type,
        legacy_id,
        mediapulse_id

    from {{ ref('map_streaming_legacy_fields') }}

),

final as (

    select
        watch_events.event_id,
        user_map.mediapulse_id as user_id,
        watch_events.legacy_subscriber_id,
        content_map.mediapulse_id as content_id,
        watch_events.legacy_content_id,
        watch_events.watched_at,
        watch_events.watch_duration_seconds,
        watch_events.device_type,
        cast(null as timestamp_ntz) as batched_at

    from watch_events
    left join id_map as user_map
        on watch_events.legacy_subscriber_id = user_map.legacy_id
        and user_map.mapping_type = 'user_id'
    left join id_map as content_map
        on watch_events.legacy_content_id = content_map.legacy_id
        and content_map.mapping_type = 'content_id'

)

select * from final
