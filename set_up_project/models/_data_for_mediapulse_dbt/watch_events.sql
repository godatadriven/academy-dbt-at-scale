{{
    config(
        database='mediapulse_raw',
        schema='streaming'
    )
}}


-- =====================================================================
-- touchpoints_backfill_with_spike.sql  (Snowflake / dbt)
--
-- What this does:
--   1. Backfills "normal" synthetic touchpoints for every day between the
--      last date in the source data and yesterday (current_date - 1).
--   2. Injects an anomaly on (spike_date - 1 day): ~120x the normal daily
--      volume, all against "live" content, with much longer watch durations
--      than usual - simulating a live-event traffic spike.
--
-- Edit before running:
--   - spike_date          : the date you're targeting (spike lands the day before it)
--   - live_content_ids    : the content_ids that should count as "live" content
--   - ref('stg_touchpoints'): point this at your actual touchpoints model/table
-- =====================================================================

{%- set spike_date = '2026-09-20' %}
{%- set live_content_ids = ['cnt_010', 'cnt_045', 'cnt_058', 'cnt_082'] %}

with watch_events as (

    select * from {{ ref("raw_streaming__watch_events_static") }}

),

bounds as (
    select
        max(watched_at::date)                        as last_existing_date,
        dateadd(day, -1, current_date())              as yesterday_date,
        '{{ spike_date }}'::date                      as spike_date,
        dateadd(day, -1, '{{ spike_date }}'::date)    as spike_day
    from watch_events
),
 
-- normal daily volume, used as the baseline both for the backfill and
-- as the multiplier base for the spike (avg_daily_events * 120)
daily_stats as (
    select
        round(count(*) / count(distinct watched_at::date)) as avg_daily_events
    from watch_events
),
 
device_pool as (
    select array_agg(distinct device_type) as devices from watch_events
),
 
user_pool as (
    select array_agg(distinct user_id) as users from watch_events
),
 
content_pool as (
    select array_agg(distinct content_id) as contents from watch_events
),
 
-- No "is_live" column exists in the source, so live content is defined
-- explicitly via the live_content_ids Jinja list above. Replace with a
-- join to a real content dimension if/when one exists.
live_content_pool as (
    select array_agg(distinct content_id) as live_contents
    from watch_events
    where content_id in ({{ "'" ~ live_content_ids | join("','") ~ "'" }})
),
 
-- ===================== date spine: last_existing_date+1 .. yesterday =====================
row_generator_dates as (
    select seq4() as day_offset
    from table(generator(rowcount => 1000))   -- ~2.7 years of headroom; bump if needed
),
 
date_spine as (
    select dateadd(day, rg.day_offset, b.last_existing_date + 1) as event_date
    from row_generator_dates rg
    cross join bounds b
    where dateadd(day, rg.day_offset, b.last_existing_date + 1) <= b.yesterday_date
),
 
-- ===================== 1) normal backfill volume =====================
row_generator_events as (
    select seq4() as row_num
    from table(generator(rowcount => 500))    -- must cover the largest avg_daily_events you expect
),
 
backfill_candidates as (
    select ds.event_date, re.row_num
    from date_spine ds
    cross join row_generator_events re
),
 
backfill as (
    select
        'evt_bf_' || to_varchar(bc.event_date, 'YYYYMMDD') || '_' || lpad(bc.row_num, 4, '0') as event_id,
        up.users[mod(abs(random()), array_size(up.users))]::varchar    as user_id,
        cp.contents[mod(abs(random()), array_size(cp.contents))]::varchar as content_id,
        dateadd(second, uniform(0, 86399, random()), bc.event_date)          as watched_at,
        uniform(300, 10000, random())                                       as watch_duration_seconds,
        dp.devices[mod(abs(random()), array_size(dp.devices))]::varchar as device_type,
        dateadd(day, 1, bc.event_date)                                      as batched_at
    from backfill_candidates bc
    cross join user_pool up
    cross join content_pool cp
    cross join device_pool dp
    cross join daily_stats st
    where bc.row_num < st.avg_daily_events
),
 
-- ===================== 2) the spike: 120x volume, live content, long durations =====================
spike_volume as (
    select avg_daily_events * 120 as spike_row_count
    from daily_stats
),
 
row_generator_spike as (
    select seq4() as row_num
    from table(generator(rowcount => 200000))  -- must exceed max possible spike_row_count
),
 
spike as (
    select
        'evt_spike_' || to_varchar(b.spike_day, 'YYYYMMDD') || '_' || lpad(rg.row_num, 6, '0') as event_id,
        up.users[mod(abs(random()), array_size(up.users))]::varchar       as user_id,
        lp.live_contents[mod(abs(random()), array_size(lp.live_contents))]::varchar as content_id,
        dateadd(second, uniform(0, 86399, random()), b.spike_day)               as watched_at,
        uniform(15000, 40000, random())                                        as watch_duration_seconds,  -- ~2-4x the normal max
        dp.devices[mod(abs(random()), array_size(dp.devices))]::varchar   as device_type,
        dateadd(day, 1, b.spike_day)                                           as batched_at
    from row_generator_spike rg
    cross join bounds b
    cross join spike_volume sv
    cross join device_pool dp
    cross join user_pool up
    cross join live_content_pool lp
    where rg.row_num < sv.spike_row_count
)
 
select * from watch_events
union all
select * from backfill
union all
select * from spike
order by BATCHED_AT