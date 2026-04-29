with 

source as (

    select * from {{ source('streaming', 'watch_events') }}

),

renamed as (

    select
        event_id,
        user_id,
        content_id,
        watched_at,
        watch_duration_seconds,
        trim(lower(device_type)) as device_type,
        batched_at,
        MD5(
    CONCAT(
        COALESCE(event_id, ''), '|',
        COALESCE(user_id, ''), '|',
        COALESCE(watched_at, '')
    ) 
) AS hash_key,

    from source

)

select * from renamed