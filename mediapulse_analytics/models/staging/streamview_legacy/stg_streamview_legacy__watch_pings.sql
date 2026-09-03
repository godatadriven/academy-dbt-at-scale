with source as (

    select * from {{ source('streamview_legacy', 'playback_heartbeats') }}

),

renamed as (

    select
        ping_id,
        subscriber_ref    as legacy_subscriber_id,
        media_id          as legacy_content_id,
        ping_date,
        ping_time,
        try_to_timestamp_ntz(
            ping_date || ' ' || coalesce(nullif(ping_time, ''), '00:00:00'),
            'YYYY-MM-DD HH24:MI:SS'
        ) as watched_at,
        playback_position_seconds,
        device_code

    from source

)

select * from renamed
