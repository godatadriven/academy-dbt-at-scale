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
        playback_position_seconds,
        device_code

    from source

)

select * from renamed
