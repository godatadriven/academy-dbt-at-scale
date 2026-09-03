-- select * from {{ ref('mediapulse_base', 'stg_streaming__content_ctlg') }}
-- union all
-- select * from {{ ref("stg_streamview_legacy__content") }}

-- (select * from {{ ref('mediapulse_base', 'stg_streaming__subscriptions_lifecycle_rec') }} limit 100)
-- union all
-- (select
--     null as legacy_subscription_id, legacy_subscriber_id, tier, account_status, start_dt, start_tm, subscription_started_at, end_dt, end_tm, null as monthly_fee_cents, null as updated_at
-- from {{ ref("stg_streamview_legacy__subscriptions") }} limit 100)

(select * from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }} limit 100)
union all
(select
    ping_id, legacy_subscriber_id, legacy_content_id, watched_at, playback_position_seconds, device_code, null as batched_at
from {{ ref("stg_streamview_legacy__watch_pings") }} limit 100)
