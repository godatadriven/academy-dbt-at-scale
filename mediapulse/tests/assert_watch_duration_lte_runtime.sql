-- watch event: content id + watch_duration_seconds
-- content_catalog: content_id + runtime_in_minutes

select 
    * 
from {{ref('stg_streaming__watch_events')}} evnts
    join {{ref('stg_streaming__content_catalog')}} ctlg on evnts.content_id = ctlg.content_id 
where
    evnts.watch_duration_seconds > ctlg.runtime_in_minutes * 60.0