with

    source as (select * from {{ source("streaming", "watch_events") }}),

    renamed as (

        select
            md5(
                concat(
                    coalesce(event_id, ''),
                    '|',
                    coalesce(user_id, ''),
                    '|',
                    coalesce(watched_at, '')
                )
            ) as sf_hash_key,
            {{
                dbt_utils.generate_surrogate_key(
                    ["event_id", "user_id", "watched_at"]
                )
            }} as dbt_hash_key,
            event_id,
            user_id,
            content_id,
            watched_at,
            watch_duration_seconds,
            {{ clean_string("device_type") }} as device_type
        from source

    )

select *
from renamed
