select *
from {{ ref('mediapulse_base','stg_streaming__content_ctlg') }};


select *
from {{ ref('mediapulse_base','stg_streaming__subscriptions_lifecycle_rec') }};

select *
from {{ ref('mediapulse_base','stg_streaming__usr_watch_events_log') }}
