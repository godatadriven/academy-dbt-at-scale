with events as (

    select * from {{ ref('stg_streaming__usr_watch_events_log') }}

),

content_catalog as (

    select * from {{ ref('stg_streaming__content_ctlg') }}

),

subscriptions as (

    select
        *,
        try_to_timestamp_ntz(
            start_date || ' ' || coalesce(nullif(start_time, ''), '00:00:00')
        ) as subscription_started_at,
        case
            when end_date is not null then
                try_to_timestamp_ntz(
                    end_date || ' ' || coalesce(nullif(end_time, ''), '23:59:59')
                )
        end as subscription_ended_at

    from {{ ref('stg_streaming__subscriptions_lifecycle_rec') }}

),

joined as (

    select
        events.event_id,
        events.user_id,
        events.content_id,
        events.watched_at,
        events.watch_duration_seconds,
        events.device_type,
        events.batched_at,
        content_catalog.title,
        content_catalog.genre,
        content_catalog.ctnt_type,
        content_catalog.release_date,
        content_catalog.runtime_minutes,
        subscriptions.subscription_id,
        subscriptions.plan_type,
        subscriptions.status,
        subscriptions.start_date,
        subscriptions.start_time,
        subscriptions.end_date,
        subscriptions.end_time,
        subscriptions.monthly_fee_cents,
        subscriptions.subscription_started_at,
        subscriptions.subscription_ended_at

    from events
    left join content_catalog
        on events.content_id = content_catalog.content_id
    left join subscriptions
        on events.user_id = subscriptions.user_id
)

select * from joined
