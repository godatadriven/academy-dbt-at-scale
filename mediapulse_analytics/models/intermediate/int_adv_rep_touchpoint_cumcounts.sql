-- =========================================================================
-- int_advertiser_rep_touchpoint_running_counts.sql
-- Snowflake SQL — intermediate model
--
-- Purpose:
-- Row-level model. For every touchpoint, add a running (cumulative)
-- count of how many touchpoints that advertiser+rep pair has had SO FAR
-- with meaningful comments, and how many had no real text.
--
-- "So far" = inclusive of the current row, ordered by occurred_at.
-- e.g. On rep_01's 3rd call with adv_a, if calls #1 and #2 both had
-- real notes, running_touchpoints_with_comments_alltime = 3 on that row.
--
-- Provided at two grains, both cumulative:
-- - _alltime   : never resets, keeps accumulating across all years
-- - _ytd       : resets to 0 at the start of each calendar year
--
-- Source grain: one row per touchpoint (call/email/meeting/demo log entry)
-- Output grain: SAME as source — one row per touchpoint, just with
-- extra running-count columns appended.
-- =========================================================================
with
    base as (

        select
            touchpoint_id,
            advertiser_id,
            rep_id,
            touchpoint_type,
            occurred_at,
            year(occurred_at) as touchpoint_year,
            notes,
            trim(notes) as notes_trimmed,
            lower(trim(notes)) as notes_clean
        from {{ ref("stg_crm__touchpoints") }}  -- swap for your source/staging table

    ),

    classified as (

        select
            *,

            -- ---------------------------------------------------------------
            -- HAS_REAL_TEXT logic (strict mode):
            -- FALSE if any of the following hold:
            -- 1. NULL notes
            -- 2. Empty after trimming
            -- 3. Pure punctuation (".", "--", "...", etc.)
            -- 4. Common placeholder tokens (n/a, none, null, nil, test,
            -- tbd, todo, pending, repeated "x" chars, "n", "y")
            -- 5. Fewer than 3 characters (too short to be a real comment,
            -- e.g. "ok", "hi", "na")
            -- TRUE otherwise.
            -- ---------------------------------------------------------------
            case
                when notes is null
                then false
                when notes_trimmed = ''
                then false
                when regexp_like(notes_clean, '^[[:punct:]]+$')
                then false
                when
                    regexp_like(
                        notes_clean,
                        '^(n/?a|none|null|nil|test|tbd|todo|pending|x+|n|y)$'
                    )
                then false
                when length(notes_clean) < 3
                then false
                else true
            end as has_real_text

        from base

    ),

final as (

select
    touchpoint_id,
    advertiser_id,
    rep_id,
    touchpoint_type,
    occurred_at,
    touchpoint_year,
    notes,
    has_real_text,

    -- =====================================================================
    -- ALL-TIME running counts (never reset)
    -- Partitioned by advertiser + rep, ordered chronologically.
    -- touchpoint_id is a tiebreaker for deterministic ordering when two
    -- touchpoints share the exact same timestamp.
    -- =====================================================================
    sum(case when has_real_text then 1 else 0 end) over (
        partition by advertiser_id, rep_id
        order by occurred_at, touchpoint_id
        rows between unbounded preceding and current row
    ) as running_with_comments_alltime,

    sum(case when not has_real_text then 1 else 0 end) over (
        partition by advertiser_id, rep_id
        order by occurred_at, touchpoint_id
        rows between unbounded preceding and current row
    ) as running_no_real_text_alltime,

    -- overall touchpoint count so far, regardless of comment quality
    row_number() over (
        partition by advertiser_id, rep_id order by occurred_at, touchpoint_id
    ) as running_total_touchpoints_alltime,

    -- =====================================================================
    -- YEAR-TO-DATE running counts (reset every Jan 1)
    -- Same logic, just with touchpoint_year added to the partition.
    -- =====================================================================
    sum(case when has_real_text then 1 else 0 end) over (
        partition by advertiser_id, rep_id, touchpoint_year
        order by occurred_at, touchpoint_id
        rows between unbounded preceding and current row
    ) as running_with_comments_ytd,

    sum(case when not has_real_text then 1 else 0 end) over (
        partition by advertiser_id, rep_id, touchpoint_year
        order by occurred_at, touchpoint_id
        rows between unbounded preceding and current row
    ) as running_no_real_text_ytd,

    row_number() over (
        partition by advertiser_id, rep_id, touchpoint_year
        order by occurred_at, touchpoint_id
    ) as running_total_touchpoints_ytd

from classified
order by advertiser_id, rep_id, occurred_at

)

select * from final