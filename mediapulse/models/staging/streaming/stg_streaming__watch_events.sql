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
        {{ clean_string('device_type') }} as device_type,
        batched_at,
        {{ dbt_utils.generate_surrogate_key(['event_id', 'user_id', 'watched_at'])}} as hash_key

--         MD5(
--     CONCAT(
--         COALESCE(event_id, ''), '|',
--         COALESCE(user_id, ''), '|',
--         COALESCE(watched_at, '')
--     ) 
-- ) AS hash_key,
    from source

)

select * from renamed