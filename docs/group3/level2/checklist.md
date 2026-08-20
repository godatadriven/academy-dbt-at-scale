# Group 3 - Checklist Level 2

## dbt Level Up

Start on this checklist once you have completed [Checklist Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Revenue mart** - fix the grain bug and allocate spend by impression share
- **Snapshots** - SCD Type 2 for campaign budget changes
- **Singular tests** - custom SQL assertions for revenue correctness
- **Documentation** - YAML for staging and mart models

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Target shape: `revenue_by_content`

You'll build the mart up step by step. Refer back to this table whenever you need to know what column comes from where, or what the final grain should look like.

**Grain:** one row per `(campaign_id, content_id, impression_date)`.

| Column | Source | What it is |
|---|---|---|
| `campaign_id` | `fct_ad_impressions` | Foreign key to `stg_ads__campaigns` |
| `content_id` | `fct_ad_impressions` | The content item the impression ran against |
| `impression_date` | `fct_ad_impressions` | Day the impressions were served |
| `impressions_count` | `fct_ad_impressions` | Impressions for this `(campaign, content, date)` |
| `campaign_type` | `stg_ads__campaigns` | Drives the commission rate lookup |
| `spend_dollars` | `stg_ads__spend` | Gross daily campaign spend |
| `net_spend_dollars` | `stg_ads__spend` | Spend minus platform fees |
| `impression_share` | derived | `impressions_count / total_campaign_impressions` for the day |
| `allocated_spend_dollars` | derived | `impression_share × spend_dollars` |
| `allocated_net_spend_dollars` | derived | `impression_share × net_spend_dollars` |
| `commission_rate` | `commission_lookup` seed | MediaPulse's cut for this campaign type |
| `mediapulse_revenue_dollars` | derived | `allocated_net_spend_dollars × commission_rate` |

---

## Step 1 - Get the grain right in `revenue_by_content.sql`

- [ ] Step complete

Open `models/marts/revenue/revenue_by_content.sql`. There's an existing model - you'll work *from* it, not throw it away. The model already has `spend` and `campaigns` CTEs you'll keep using in later steps; what's broken is the final aggregation, which groups at `campaign_id` and loses the per-content breakdown the mart name promises.

For this step, focus on **just one thing: getting the grain right**. Add an `impressions` CTE that pulls from `fct_ad_impressions`, then replace the broken `campaign_revenue` CTE with a `final` CTE at the impression grain (`campaign_id, content_id, impression_date`).

Leave the `spend` and `campaigns` CTEs in place; you'll use them for enrichment in Step 2.

??? tip "Hint: Why the existing aggregation is wrong"
    The model groups by `campaign_id, campaign_name, campaign_type, advertiser_id` - there's no `content_id` in the `GROUP BY`. You get one row per campaign, not one row per content item per campaign per day. The mart is named "by content" but doesn't actually break down by content.

??? tip "Hint: Skeleton"
    ```sql
    with spend as (
        select * from {{ ref('stg_ads__spend') }}
    ),

    campaigns as (
        select * from {{ ref('stg_ads__campaigns') }}
    ),

    impressions as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count
        from {{ ref('fct_ad_impressions') }}
    ),

    final as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count
        from impressions
    )

    select * from final
    ```

    Run it and confirm the row count matches `fct_ad_impressions`:

    ```bash
    dbt run --select revenue_by_content
    ```

---

## Step 2 - Enrich with only what's needed downstream

- [ ] Step complete

Now bring in the additional columns the *downstream* logic actually requires - and nothing more. Use the `spend` and `campaigns` CTEs that are already at the top of the file (no need to re-declare them). Resist the temptation to pull `campaign_name`, `advertiser_id`, or anything else "just in case" - check the [target shape table](#target-shape-revenue_by_content) above if you're unsure whether a column will be needed.

What downstream needs are concrete?

- The commission lookup (a later step) joins `commission_lookup` on `campaign_type`. So you need `campaign_type` from `campaigns`.
- The allocation calculation (also later) multiplies impression share by gross and net spend. So you need `spend_dollars` and `net_spend_dollars` from `spend`, joined on `(campaign_id, spend_date = impression_date)`.

Add an enrichment CTE between `impressions` and `final`, and pass those columns through. The grain should not change.

??? tip "Hint: Enriched skeleton"
    ```sql
    with spend as (
        select * from {{ ref('stg_ads__spend') }}
    ),

    campaigns as (
        select * from {{ ref('stg_ads__campaigns') }}
    ),

    impressions as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count
        from {{ ref('fct_ad_impressions') }}
    ),

    enriched as (
        select
            i.campaign_id,
            i.content_id,
            i.impression_date,
            i.impressions_count,
            c.campaign_type,
            s.spend_dollars,
            s.net_spend_dollars
        from impressions i
        inner join campaigns c
            using (campaign_id)
        inner join spend s
            on  i.campaign_id    = s.campaign_id
            and i.impression_date = s.spend_date
    ),

    final as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count,
            campaign_type,
            spend_dollars,
            net_spend_dollars
        from enriched
    )

    select * from final
    ```

    Re-run the model and confirm the row count is unchanged from Step 1 - if it dropped, your join is filtering rows it shouldn't.

---

## Step 3 - Compute the derived metrics and finalize the mart

- [ ] Step complete

Now layer the math on top of the `enriched` CTE so the mart matches the [target shape table](#target-shape-revenue_by_content). There are three derivations to add, in order:

1. **`impression_share`** - what fraction of a campaign's total impressions on a given day belongs to this content item? Compute it from `impressions_count` divided by the total across all content for the same `(campaign_id, impression_date)`. Watch out for divide-by-zero.
2. **`allocated_spend_dollars` and `allocated_net_spend_dollars`** - multiply the share by gross and net spend for the row's `(campaign_id, impression_date)`.
3. **`commission_rate` and `mediapulse_revenue_dollars`** - bring in `commission_rate` from the `commission_lookup` seed by joining on `campaign_type`, then multiply by `allocated_net_spend_dollars`. Use a **`left join`** so a missing commission rate surfaces as a NULL revenue row rather than silently dropping the content.

After this step, the row count should still match Step 1 and the column list should match the target shape table exactly.

??? tip "Hint: Computing `impression_share` with a window function"
    The "total campaign impressions per day" can be computed without a separate aggregation CTE - a window function does it in one pass:

    ```sql
    impressions_count
        / nullif(sum(impressions_count) over (
            partition by campaign_id, impression_date
        ), 0) as impression_share
    ```

??? tip "Hint: Full model"
    The complete `revenue_by_content.sql` after this step:

    ```sql
    with spend as (
        select * from {{ ref('stg_ads__spend') }}
    ),

    campaigns as (
        select * from {{ ref('stg_ads__campaigns') }}
    ),

    impressions as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count
        from {{ ref('fct_ad_impressions') }}
    ),

    enriched as (
        select
            i.campaign_id,
            i.content_id,
            i.impression_date,
            i.impressions_count,
            c.campaign_type,
            s.spend_dollars,
            s.net_spend_dollars
        from impressions i
        inner join campaigns c
            using (campaign_id)
        inner join spend s
            on  i.campaign_id    = s.campaign_id
            and i.impression_date = s.spend_date
    ),

    with_share as (
        select
            *,
            impressions_count
                / nullif(sum(impressions_count) over (
                    partition by campaign_id, impression_date
                ), 0) as impression_share
        from enriched
    ),

    allocated as (
        select
            *,
            impression_share * spend_dollars     as allocated_spend_dollars,
            impression_share * net_spend_dollars as allocated_net_spend_dollars
        from with_share
    ),

    with_commission as (
        select
            a.*,
            cl.commission_rate,
            a.allocated_net_spend_dollars * cl.commission_rate as mediapulse_revenue_dollars
        from allocated a
        left join {{ ref('commission_lookup') }} cl using (campaign_type)
    )

    select
        campaign_id,
        content_id,
        impression_date,
        impressions_count,
        campaign_type,
        spend_dollars,
        net_spend_dollars,
        impression_share,
        allocated_spend_dollars,
        allocated_net_spend_dollars,
        commission_rate,
        mediapulse_revenue_dollars
    from with_commission
    ```

    After running, spot-check a single `(campaign_id, impression_date)` and confirm the impression shares for that combination sum to roughly 1.0, and that the allocated spend rows sum to the campaign's gross spend for the day.

---

## Step 4 - Reason about why we need a snapshot

- [ ] Step complete

Before writing any code, take 5-10 minutes with your group to work through the questions below and **write your answers down** - you'll feed them straight into Step 5 to make concrete config choices.

1. **The state-overwrite problem.** `stg_ads__campaigns` is rebuilt on every run from `ads.campaigns`. If an advertiser bumped their `budget_cents` from `500000` to `1000000` last week, what does `stg_ads__campaigns` say the budget was *yesterday*? What did the source actually say yesterday?

2. **What you lose.** Name two business questions about a campaign you can only answer if you've kept a history of past values - and would silently get the wrong answer for if you just used `stg_ads__campaigns`. (Think pacing reports, audit trails, mid-flight budget changes.)

3. **Which columns move?** Open `seeds/raw_ads__campaigns.csv` (or `select * from ads.campaigns limit 5`) and look at the columns: `campaign_id, advertiser_id, campaign_name, campaign_type, start_date, end_date, budget_cents`. Which of these are realistically going to change after a campaign launches? Which ones are essentially static?

4. **Update marker.** dbt's `timestamp` snapshot strategy needs a single column it can use as the "this row was updated at" marker. Looking at the column list above, is there one? (...there isn't. Note that down - it'll force a strategy choice in Step 5.)

5. **(Optional, if time permits)** Snapshots implement **Slowly Changing Dimension Type 2**. Skim the [dbt snapshots docs](https://docs.getdbt.com/docs/build/snapshots) for what `dbt_valid_from`, `dbt_valid_to`, and `dbt_scd_id` mean. Sketch out what the rows for a single campaign look like after dbt detects a budget change.

??? tip "Hint: The core problem in one sentence"
    `stg_ads__campaigns` overwrites itself on every run, so the previous values disappear forever. Any analytics question about "what was true on date X?" silently uses today's values instead - producing answers that look reasonable but are wrong (e.g. a campaign appears to be delivering nicely "under budget", because the budget was actually bumped last Tuesday, not because spend was controlled).

??? tip "Hint: What `check` strategy looks like, conceptually"
    Without an `updated_at` column, dbt can't know whether a row changed unless you tell it which columns to compare. The `check` strategy takes a list of columns and creates a new SCD row whenever any of those columns differ from the last snapshotted version. The cost is that you have to maintain that column list as the schema evolves.

---

## Step 5 - Create the snapshot

- [ ] Step complete

Now turn the answers from Step 4 into config. Create `snapshots/snap_ads__campaigns.yml`. Three things you've effectively decided already:

1. **`unique_key`** - which column identifies a campaign across versions (your answer to Step 4 question 1's "what is a campaign?").
2. **`strategy`** - your answer to Step 4 question 4 should rule out `timestamp`. Use `check` instead.
3. **`check_cols`** - the list of columns from Step 4 question 3 that actually move.

??? tip "Hint: Snapshot skeleton"
    ```yaml
    snapshots:
    - name: <string>
        relation: ref() | source()
        config:
        database: <string>
        schema: <string>
        unique_key: <column_name_or_expression>
        strategy: timestamp | check
        updated_at: <column_name> # only needed with timestamp strategy
        check_cols: [<column_name>] | all # only needed with check strategy
    ```

    Run it:

    ```bash
    dbt snapshot --select snap_ads__campaigns
    ```

    Then query the snapshot table - dbt will have added `dbt_scd_id`, `dbt_valid_from`, `dbt_valid_to`, and `dbt_updated_at`. On this first run every row has `dbt_valid_to is null` (it's the current version of each campaign). The history would start to accumulate the moment a watched column changed upstream - in production the snapshot job runs on a schedule, and any subsequent change to `budget_cents`, `end_date`, or `campaign_type` would close out the existing row (`dbt_valid_to = now()`) and insert a new one (`dbt_valid_from = now()`, `dbt_valid_to = null`).

---

## Step 6 - Write a singular test: revenue is never null

- [ ] Step complete

Create `tests/assert_revenue_not_null.sql`. Every row in `revenue_by_content` represents spend MediaPulse has allocated to content, so every row should have a derivable `mediapulse_revenue_dollars` value. A NULL there means we've allocated spend we can't attribute revenue to.

??? tip "Hint: When does a dbt test pass?"
    A test **passes** when the query returns **zero rows** - any rows returned are failures.

??? tip "Hint"
    ```sql
    select *
    from {{ ref('revenue_by_content') }}
    where mediapulse_revenue_dollars is null
    ```

    Run it:

    ```bash
    dbt test --select assert_revenue_not_null
    ```

---

## Step 7 - Write singular test: no negative spend

- [ ] Step complete

Create `tests/assert_no_negative_spend.sql`. Negative values in `stg_ads__spend` indicate a data pipeline issue upstream.

??? tip "Hint"
    ```sql
    select spend_id, spend_date, spend_dollars
    from {{ ref('stg_ads__spend') }}
    where spend_dollars < 0
       or net_spend_dollars < 0
    ```

    Run it:

    ```bash
    dbt test --select assert_no_negative_spend
    ```

---

## Step 8 - Add YAML for staging models and the mart

- [ ] Step complete

Create `models/staging/ads/_ads__models.yml` and `models/marts/revenue/_revenue__models.yml`. Document columns and add tests.

Include at minimum:

- **Primary keys** - on every model (`stg_ads__campaigns`, `stg_ads__spend`, `stg_ads__impressions`, `fct_ad_impressions`), add `not_null` and `unique` tests on the PK column (`campaign_id`, `spend_id`, `impression_id`, `impression_id`). For `revenue_by_content`, the PK is the composite `(campaign_id, content_id, impression_date)` - cover that with a `dbt_utils.unique_combination_of_columns` test.
- **Not-null on the columns the mart depends on** - at minimum the foreign keys and the columns used in joins or measures: `campaign_id`, `content_id`, `impression_date`, `impressions_count`, `campaign_type`, `spend_dollars`, `net_spend_dollars`. A NULL in any of these silently breaks downstream joins or measures.
- A `relationships` test on `fct_ad_impressions.campaign_id` → `stg_ads__campaigns.campaign_id`.
- A `relationships` test on `stg_ads__campaigns.campaign_type` → `commission_lookup.campaign_type`. Every campaign type that appears in the data needs a commission rate downstream - this test enforces that. If it fails, don't just silence it; query the failing rows and work out *why* the lookup is missing them.
- An `accepted_values` test on `campaign_type` in `stg_ads__campaigns`. Level 3 Step 2 will reconfigure this test - so make sure it exists.

!!! info "Figuring out the accepted values"
    You need to decide what values to put in the test. Two reasonable approaches:

    - Query `stg_ads__campaigns` and pull the distinct `campaign_type` values.
    - Look at `seeds/commission_lookup.csv` - the seed already enumerates the campaign types the platform supports.

    The two should agree. If they don't, that's itself a finding worth noting - and the `relationships` test above will tell you *which* values are out of sync.

??? tip "Hint: Relationships test"
    ```yaml
    - name: campaign_id
      data_tests:
        - not_null
        - relationships:
            arguments:
              to: ref('stg_ads__campaigns')
              field: campaign_id
    ```

---

## Step 9 - Run `dbt build --select +revenue_by_content`

- [ ] Step complete

```bash
dbt build --select +revenue_by_content
```

This builds the full lineage - sources → staging → incremental fact → mart - and runs all tests. Fix any failures.

??? tip "Hint: If `assert_revenue_not_null` fails"
    Look at the failing rows and check the `campaign_type` column. The most likely cause is a `campaign_type` value that exists in `stg_ads__campaigns` but isn't in `seeds/commission_lookup.csv`, so the left join in `revenue_by_content` produces a NULL `commission_rate` (and therefore a NULL `mediapulse_revenue_dollars`). The relationships test you added in Step 8 (`stg_ads__campaigns.campaign_type → commission_lookup.campaign_type`) should fail at the same time and point at the same root cause.

---

!!! success "Done?"
    You've built the revenue spine of the MediaPulse data platform - a correct-grain mart, a campaign budget snapshot, and custom SQL assertions that verify revenue integrity.

    Now head to [Level 3](../level3/checklist.md) to configure your tests with severity, `where` clauses, and `dbt_expectations` guardrails on your revenue models!

