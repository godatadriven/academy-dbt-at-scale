with source as (

    select * from {{ source('streaming', 'usr_watch_events_log') }}

),

renamed as (

    select
        event_id,
        user_id,
        content_id,
        watched_at,
        watch_duration_seconds,
        device_type,
        batched_at

    from source

)

select * from renamed