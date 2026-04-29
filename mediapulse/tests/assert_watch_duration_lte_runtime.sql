-- Returns rows where a watch event is longer than the content's runtime.
-- Zero rows = test passes.
select
    content_id, watch_duration_seconds, runtime_minutes
from {{ ref("stg_streaming__watch_events") }} w
left join {{ ref("stg_streaming__content_catalog") }} c
    using (content_id)
where w.watch_duration_seconds/60 > c.runtime_minutes