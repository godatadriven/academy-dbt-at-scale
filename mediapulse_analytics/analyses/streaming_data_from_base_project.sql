-- Content
select * --grain: content_id
from {{ ref('mediapulse_base', 'stg_streaming__content_ctlg') }}
select * --grain: content_id
from {{ ref('stg_streamview_legacy__content') }}

-- Subscriptions
select * -- grain: One row per subscription lifecycle event
from {{ ref('mediapulse_base', 'stg_streaming__subscriptions_lifecycle_rec') }}
select * -- grain: One row per legacy subscriber account.
from {{ ref('stg_streamview_legacy__subscriptions') }}

-- Watch events
select * --One row per playback event
from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}
select * --One row per ping, recorded roughly once per minute of playback.
from {{ ref('stg_streamview_legacy__watch_pings')}}


-- Data period
select 
    min(ping_date)
    , max(ping_date)
from {{ ref('stg_streamview_legacy__watch_pings')}}
-- MIN(PING_DATE) 2023-01-01
-- MAX(PING_DATE) 2026-06-30

select 
    min(watched_at)
    , max(watched_at)
from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}
-- MIN(watched_at) 2024-01-01 00:21:00
-- MAX(watched_at) 2024-06-30 22:29:00

