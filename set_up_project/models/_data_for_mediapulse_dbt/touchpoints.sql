{{
    config(
        database='mediapulse_raw',
        schema='crm'
    )
}}

{% set spike_date = '2026-08-27' %}

/* =====================================================================
   preview_touchpoints_with_fraud_spike.sql

   Preview-only version -- no INSERT INTO, just a combined SELECT so you
   can eyeball the generated rows before writing anything.

   Produces two blocks of synthetic rows, unioned together:

   1. FILLER  -- normal-volume touchpoints from the day after the last
      existing row through YESTERDAY (dynamic: DATEADD(day,-1,
      CURRENT_DATE()), so this always catches up to "yesterday"
      relative to whenever you run it).

   2. SPIKE   -- a fraud-news-driven flood of concerned client
      touchpoints hardcoded to 2026-08-27, sized to ~100x the account's
      actual recent daily average (computed from the real data, not
      guessed).

   NOTE: rename CRM_TOUCHPOINTS below to your actual table name.
   ===================================================================== */

WITH crm_touchpoints as (select * from {{ ref("raw_crm__touchpoints_static") }}),

pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'adv_a','adv_b','adv_c','adv_d','adv_e','adv_f','adv_g','adv_h',
            'adv_i','adv_j','adv_k','adv_l','adv_m','adv_n','adv_o','adv_p',
            'adv_q','adv_r','adv_s','adv_t'
        ) AS advertisers,
        ARRAY_CONSTRUCT(
            'rep_01','rep_02','rep_03','rep_04','rep_05','rep_06','rep_07','rep_08'
        ) AS reps,
        ARRAY_CONSTRUCT('call','email','meeting','demo') AS types,
        ARRAY_CONSTRUCT(
            'Discussed {topic} with client',
            'Sent updated deck covering {topic} to stakeholders',
            'Client pushed back on pricing during {topic} discussion',
            'Scheduled follow-up meeting to continue {topic} conversation',
            'Walked client through {topic}',
            'Kickoff call for {topic}',
            'Reviewed contract terms tied to {topic}, legal reviewing redlines',
            'Advertiser asked for case studies related to {topic}',
            'Great meeting - advertiser committed to renewing after {topic} review',
            'Client requested changes to {topic}, will revise and resend'
        ) AS note_templates,
        ARRAY_CONSTRUCT(
            'Q3 budget planning','Q2 renewal','brand values campaign brief',
            'mid-flight performance summary','audience segment review',
            'contract renewal terms','social media bundle upsell',
            'newsletter renewal','Champions League placement',
            'influencer partnership pitch','pricing negotiation',
            'holiday campaign brief'
        ) AS topics
),
 
spike_pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'adv_a','adv_b','adv_c','adv_d','adv_e','adv_f','adv_g','adv_h',
            'adv_i','adv_j','adv_k','adv_l','adv_m','adv_n','adv_o','adv_p',
            'adv_q','adv_r','adv_s','adv_t'
        ) AS advertisers,
        ARRAY_CONSTRUCT(
            'rep_01','rep_02','rep_03','rep_04','rep_05','rep_06','rep_07','rep_08'
        ) AS reps,
        -- weighted toward call/email: an inbound-concern flood is
        -- reactive contact, not scheduled meetings or demos
        ARRAY_CONSTRUCT(
            'call','call','call','call','call','call',
            'email','email','email','email',
            'meeting',
            'demo'
        ) AS types,
        ARRAY_CONSTRUCT(
            'Client called in a panic after seeing the news story about ad fraud rings - wants written assurance we are not implicated',
            'Advertiser saw this morning''s fraud exposé and is pausing spend until we confirm we are unaffected',
            'Urgent: client asking whether their campaign was exposed in the ad fraud investigation reported today',
            'Client requesting an emergency call re: today''s fraud story, worried about brand safety',
            'Received multiple calls today about the fraud news - client wants a compliance statement ASAP',
            'Advertiser flagged concern about being named in the fraud investigation, escalating to legal',
            'Client demanding proof our impression data was not affected by the fraud network in today''s report',
            'Spoke with client about today''s fraud allegations - reassured them our platform uses independent verification',
            'Client threatening to pause all campaigns pending an internal fraud audit after today''s news',
            'Inbound call: client saw the fraud story on the news and wants immediate clarification',
            'Advertiser asked for our fraud-prevention documentation following today''s investigative report',
            'Client''s legal team reached out re: potential exposure following today''s ad fraud news',
            'Client asking to pause billing until the fraud investigation is resolved',
            'Advertiser wants a call with senior leadership about today''s fraud story before renewing anything'
        ) AS notes_pool
),
 
last_touchpoint AS (
    SELECT
        MAX(occurred_at)::DATE AS last_date,
        MAX(TRY_TO_NUMBER(SPLIT_PART(touchpoint_id, '_', 2))) AS last_seq
    FROM crm_touchpoints
),
 
baseline_volume AS (
    SELECT
        GREATEST(ROUND(COUNT(*) / 90.0), 1) AS avg_daily_touchpoints
    FROM crm_touchpoints
    WHERE occurred_at >= DATEADD(day, -90, (SELECT MAX(occurred_at) FROM crm_touchpoints))
),
 
-- ---------------------------------------------------------------------
-- 1. FILLER candidates: last existing date+1 -> yesterday
-- ---------------------------------------------------------------------
filler_days AS (
    SELECT touch_date
    FROM (
        SELECT
            DATEADD(day, SEQ4(), DATEADD(day, 1, (SELECT last_date FROM last_touchpoint))) AS touch_date
        FROM TABLE(GENERATOR(ROWCOUNT => 5000))
    )
    WHERE touch_date <= DATEADD(day, -1, CURRENT_DATE())  -- "yesterday", dynamic
),
 
filler_expanded AS (
    SELECT
        d.touch_date,
        s.value::INT AS daily_seq
    FROM filler_days d,
         TABLE(FLATTEN(ARRAY_GENERATE_RANGE(0, UNIFORM(1, 3, RANDOM())))) s
),
 
filler_rows AS (
    SELECT
        f.touch_date,
        f.daily_seq,
        -- bounds are hardcoded literals (UNIFORM requires constants) --
        -- they match the fixed array sizes defined in `pools` above:
        -- 20 advertisers, 8 reps, 4 types, 10 note_templates, 12 topics
        p.advertisers[UNIFORM(0, 19, RANDOM())]::STRING AS advertiser_id,
        p.reps[UNIFORM(0, 7, RANDOM())]::STRING AS rep_id,
        p.types[UNIFORM(0, 3, RANDOM())]::STRING AS touchpoint_type,
        DATEADD(
            second,
            UNIFORM(25200, 66600, RANDOM()),  -- ~07:00 to ~18:30
            f.touch_date::TIMESTAMP
        ) AS occurred_at,
        REPLACE(
            p.note_templates[UNIFORM(0, 9, RANDOM())]::STRING,
            '{topic}',
            p.topics[UNIFORM(0, 11, RANDOM())]::STRING
        ) AS notes
    FROM filler_expanded f
    CROSS JOIN pools p
),
 
-- ---------------------------------------------------------------------
-- 2. SPIKE candidates: fraud-news flood on 2026-08-27
-- ---------------------------------------------------------------------
spike_target AS (
    SELECT avg_daily_touchpoints * 100 AS target_row_count
    FROM baseline_volume
),
 
spike_candidates AS (
    SELECT rn
    FROM (
        SELECT SEQ4() AS rn
        FROM TABLE(GENERATOR(ROWCOUNT => 5000))
    )
    WHERE rn < (SELECT target_row_count FROM spike_target)
),
 
spike_rows AS (
    SELECT
        {{ spike_date }}::DATE AS touch_date,
        c.rn AS daily_seq,
        -- bounds are hardcoded literals (UNIFORM requires constants) --
        -- they match the fixed array sizes defined in `spike_pools` above:
        -- 20 advertisers, 8 reps, 12 weighted types, 14 notes_pool
        p.advertisers[UNIFORM(0, 19, RANDOM())]::STRING AS advertiser_id,
        p.reps[UNIFORM(0, 7, RANDOM())]::STRING AS rep_id,
        p.types[UNIFORM(0, 11, RANDOM())]::STRING AS touchpoint_type,
        DATEADD(
            second,
            UNIFORM(21600, 72000, RANDOM()),  -- spread ~06:00 to ~20:00
            {{ spike_date }}::TIMESTAMP
        ) AS occurred_at,
        p.notes_pool[UNIFORM(0, 13, RANDOM())]::STRING AS notes
    FROM spike_candidates c
    CROSS JOIN spike_pools p
),
 
-- ---------------------------------------------------------------------
-- Combine both previews with generated (not-yet-real) touchpoint_ids
-- ---------------------------------------------------------------------
combined AS (
    SELECT 'tp_' || LPAD(
        (SELECT last_seq FROM last_touchpoint) + ROW_NUMBER() OVER (ORDER BY occurred_at),
        4, '0'
    ) AS touchpoint_id,
    advertiser_id,
    rep_id,
    touchpoint_type,
    occurred_at,
    notes FROM filler_rows
    UNION ALL
    SELECT 'tp_' || LPAD(
        (SELECT last_seq FROM last_touchpoint) + ROW_NUMBER() OVER (ORDER BY occurred_at),
        4, '0'
    ) AS touchpoint_id,
    advertiser_id,
    rep_id,
    touchpoint_type,
    occurred_at,
    notes FROM spike_rows
    UNION ALL
    SELECT * FROM crm_touchpoints
)
 
SELECT 
    *
FROM combined
ORDER BY occurred_at