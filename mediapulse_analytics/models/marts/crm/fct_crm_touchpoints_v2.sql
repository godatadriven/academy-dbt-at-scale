-- fct_crm_touchpoints v2: one row per sales touchpoint, with the activity
-- timestamp split into date and time fields.
{{ config(materialized='table') }}

with touchpoints as (

    select * from {{ ref('int_adv_rep_touchpoint_cumcounts') }}

),

reps as (

    select
        rep_id,
        rep_name

    from {{ ref('stg_crm__sales_reps') }}

)

select
    touchpoints.touchpoint_id,
    touchpoints.advertiser_id,
    touchpoints.rep_id,
    reps.rep_name,
    touchpoints.touchpoint_type,
    touchpoints.occurred_at::date as occurred_at_date,
    touchpoints.occurred_at::time as occurred_at_time,
    touchpoints.notes

from touchpoints
left join reps
    on touchpoints.rep_id = reps.rep_id
