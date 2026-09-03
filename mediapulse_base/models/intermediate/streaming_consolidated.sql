WITH current_data AS(
    select 
from {{ ref('mediapulse_base','stg_streaming__usr_watch_events_log') }}
), historical_data AS(
    select ping_id AS event_id
    , legacy_subscriber_id AS user_id
    , legacy_content_id AS content_id
    , CONCAT(PING_DATE,-)
    from {{ ref('stg_streamview_legacy__watch_pings') }}
)
select *
from historical_data