with watch_events_new as (
    select * from {{ ref('mediapulse_base', 'stg_streaming__usr_watch_events_log') }}
),
watch_events_legacy_transformed as (
    select * from {{ ref('int_streaming__legacy_watch_events_reshaped') }}

)
select * from watch_events_new
union all 
select * from watch_events_legacy_transformed