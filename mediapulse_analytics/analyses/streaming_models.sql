select * from {{ ref('mediapulse_base', 'stg_streaming__content_ctlg') }} limit 100

select * from {{ ref('mediapulse_base', 'stg_streaming__subscriptions_lifecycle_rec') }} limit 100

select * from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }} limit 100
