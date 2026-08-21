-- fct_legacy_subscription_lifecycle_events: one row per lifecycle event
-- (subscription_started, subscription_ended) for each StreamView legacy
-- subscriber. Unpivots dim_legacy_subscribers' two lifecycle timestamps into
-- an event log.

with subscribers as (

    select * from {{ ref('dim_legacy_subscribers') }}

),

started as (

    select
        legacy_subscriber_id,
        mapped_user_id,
        'subscription_started'    as event_type,
        subscription_started_at   as event_at,
        tier

    from subscribers

),

ended as (

    select
        legacy_subscriber_id,
        mapped_user_id,
        'subscription_ended'    as event_type,
        subscription_ended_at   as event_at,
        tier

    from subscribers
    where subscription_ended_at is not null

)

select * from started
union all
select * from ended
