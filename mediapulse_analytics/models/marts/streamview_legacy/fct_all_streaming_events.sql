with legacy_events as (

    select
        event_id,
        user_id,
        legacy_subscriber_id,
        content_id,
        legacy_content_id,
        watched_at,
        watch_duration_seconds,
        device_type,
        -- StreamView did not record when heartbeat data was loaded in a batch.
        batched_at,
        true as is_legacy

    from {{ ref('int_streamview_legacy__watch_events') }}

),

current_events as (

    select
        event_id,
        user_id,
        -- Current-platform events have no StreamView identifiers.
        cast(null as varchar) as legacy_subscriber_id,
        content_id,
        cast(null as varchar) as legacy_content_id,
        try_to_timestamp_ntz(watched_at) as watched_at,
        watch_duration_seconds,
        device_type,
        batched_at,
        false as is_legacy

    from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}

),

combined as (

    select * from legacy_events
    union all
    select * from current_events

)

select * from combined
