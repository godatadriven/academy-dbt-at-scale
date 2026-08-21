-- dim_legacy_subscribers: one row per StreamView (legacy) subscriber account,
-- resolved to a current MediaPulse user_id where a mapping exists in
-- map_streaming_legacy_fields. Not every legacy subscriber has been migrated yet.

with subscriptions as (

    select * from {{ ref('stg_streamview_legacy__subscriptions') }}

),

id_map as (

    select
        legacy_id,
        mediapulse_id

    from {{ ref('map_streaming_legacy_fields') }}
    where mapping_type = 'user_id'

)

select
    subscriptions.legacy_subscriber_id,
    lower(subscriptions.tier)              as tier,
    lower(subscriptions.account_status)    as account_status,
    try_to_timestamp_ntz(
        subscriptions.start_dt || ' ' || coalesce(nullif(subscriptions.start_tm, ''), '00:00:00')
    )                                       as subscription_started_at,
    case
        when subscriptions.end_dt is not null then
            try_to_timestamp_ntz(
                subscriptions.end_dt || ' ' || coalesce(nullif(subscriptions.end_tm, ''), '23:59:59')
            )
    end                                     as subscription_ended_at,
    id_map.mediapulse_id                    as mapped_user_id,
    id_map.mediapulse_id is not null        as is_mapped

from subscriptions
left join id_map
    on subscriptions.legacy_subscriber_id = id_map.legacy_id
