# Group 3 - Checklist Level 1

## dbt Fundamentals + Incremental Models

This track requires the most technical depth. If you're stuck on a concept, re-read the [Overview](../overview.md) or ask your instructor before expanding a hint.

In this level you will:

- **Explore and define sources** for the ads domain
- **Build three staging models**
- **Create a seed** for commission rate lookups
- **Build an incremental fact table** - the high-volume spine of the revenue model
- **Understand incremental trade-offs**

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Explore the raw ads tables

- [ ] Step complete

Query the three `ads` tables and understand the grain of each:

```sql
select * from ads.campaigns limit 10;
select * from ads.impressions limit 10;
select * from ads.spend limit 10;
```

Answer:

- What is the grain of `impressions`, `spend` and `campaigns`? (one row per what?)
- Can a campaign appear in `spend` multiple times? When?
- What unit is `budget_cents` in? What about `spend_cents`?

??? tip "Hint: Grain analysis"
    - `campaigns`: one row per campaign (SCD-friendly - budget can change)
    - `impressions`: one row per `(campaign_id, content_id, impression_date)` - daily aggregate
    - `spend`: one row per `(campaign_id, spend_date)` - can have multiple rows per campaign as days accumulate.

    All monetary values are in cents. You'll need a macro or inline calculation to convert.

---

## Step 2 - Define sources in YAML

- [ ] Step complete

Create `models/staging/ads/_ads__sources.yml`. Define a source named `ads` with all three tables.

Before writing the YAML, think: what tests would actually be useful here? Sources are the boundary between your warehouse and the rest of the pipeline - if a column you rely on is silently null or duplicated upstream, every model downstream inherits that bug. Pick the tests that catch the assumptions you're already making about the raw data (which column uniquely identifies a row? which columns must always be populated for the model to make sense?), and apply them per table.

??? tip "Hint: Source definition"
    ```yaml
    version: 2

    sources:
      - name: ads
        schema: ads
        tables:
          - name: campaigns
            columns:
              - name: campaign_id
                tests: [not_null, unique]
          - name: impressions
            columns:
              - name: impression_id
                tests: [not_null, unique]
          - name: spend
            columns:
              - name: spend_id
                tests: [not_null, unique]
    ```

---

## Step 3 - Create `seeds/commission_lookup.csv`

- [ ] Step complete

MediaPulse takes a platform commission from ad revenue that varies by campaign type. Create this seed:

```csv
campaign_type,commission_rate
display,0.15
video,0.20
sponsored_content,0.25
podcast-ad,0.18
newsletter,0.12
```

Place it at `seeds/commission_lookup.csv` and load it:

```bash
dbt seed --select commission_lookup
```

??? tip "Hint: Why a seed?"
    Commission rates change occasionally (e.g., when MediaPulse renegotiates with advertisers). Keeping them in a CSV means: (a) they're version-controlled, (b) anyone can change them with a PR, (c) you get a full history of rate changes in git.

    If rates changed more frequently, you'd use a source table instead.

---

## Step 4 - Build `stg_ads__campaigns.sql`

- [ ] Step complete

Create `models/staging/ads/stg_ads__campaigns.sql`. Apply the staging conventions you've seen elsewhere in the project: clean up the raw columns so the model is comfortable to consume downstream.

A couple of fields will need some transformation before they're usable - take a look at the raw data and decide what needs adjusting (think about units, casing, and any obviously-not-ready-for-analysis values).

??? tip "Hint: Things to look at"
    - Monetary values in the raw data aren't in the unit you'd want to report on - a simple inline cast/division will do for now.
    - String columns coming from upstream systems are rarely consistent in case/whitespace - normalise the obvious offenders.
    - Date-like columns may arrive as strings; cast where appropriate.

    Skeleton to get you started:

    ```sql
    with source as (
        select * from {{ source('ads', 'campaigns') }}
    ),

    renamed as (
        select
            campaign_id,
            -- ... pass through / rename / clean other columns
            -- (budget_cents / 100.0)::numeric(16, 2) as budget_dollars
        from source
    )

    select * from renamed
    ```

---

## Step 5 - Build `stg_ads__spend.sql`

- [ ] Step complete

Create `models/staging/ads/stg_ads__spend.sql`. This is a transactional table - do not deduplicate; each row is a distinct daily spend record.

While you're shaping this model, think about what *metrics* a downstream mart would actually need from spend data. Gross spend is the obvious one - but is there a more useful "what MediaPulse actually keeps" figure that can be derived from the columns you already have? Add it as a derived column (a downstream test in Level 2 will reference it).

??? tip "Hint"
    - Apply the same cents → dollars conversion you used in Step 4.
    - Look at the raw columns: there's a fee component sitting alongside gross spend. A simple subtraction gives you the "net" view.
    - **Name the derived column `net_spend_dollars`** - Level 2 and Level 3 reference it by that exact name.

---

## Step 6 - Build `stg_ads__impressions.sql`

- [ ] Step complete

Create `models/staging/ads/stg_ads__impressions.sql`. Keep the daily grain - one row per `(campaign_id, content_id, impression_date)`.

Think about what derived metrics a marketing analyst would expect from an impressions model. Raw counts are fine, but **click-through rate** is the headline metric anyone touching ad performance will look for. Add it as a column - and watch out for the obvious divide-by-zero edge case.

??? tip "Automate creating a staging layer"

    Typing every source column by hand is tedious. Two ways to skip the boilerplate - pick whichever fits your workflow:

    **Option A - the dbt Cloud `Generate model` button**

    Open `models/staging/ads/_ads__sources.yml` (the source file you created in Step 2), find the `impressions` source, and click the **Generate model** button next to it. It scaffolds a staging model with all source columns selected. Then layer your transformations (rename, cast, derived metrics) on top.

    **Option B - the `dbt-codegen` package**

    [dbt-codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/) can generate the same boilerplate `select` from the command line or an untitled file. You'll use this package again in Level 2 for YAML generation.

    1. Add the package to `packages.yml` under `dbt_utils`:

        ```yaml
        - package: dbt-labs/codegen
          version: 0.13.1
        ```

    2. Install it (it usually auto-installs; otherwise run `dbt deps`):

        ```bash
        dbt deps
        ```

    3. Open a new (or existing) untitled file in dbt Cloud, paste the following, and click `</>` **Compile**:

        ```sql
        {{ codegen.generate_base_model(
            source_name='ads',
            table_name='impressions'
        ) }}
        ```

    Either way, copy the output into `stg_ads__impressions.sql` and layer your transformations (cast `impression_date`, derive `click_through_rate`) on top.

??? tip "Hint: Things to think about"
    - One row per `(campaign_id, content_id, impression_date)` - don't aggregate further.
    - For CTR: it's `clicks / impressions_count` *but* what should the value be when `impressions_count = 0`? `nullif` or a `case` statement both work.
    - Round CTR to a sensible number of decimal places so downstream consumers don't see noise.

---

## Step 7 - Build `fct_ad_impressions.sql` (non-incremental first)

- [ ] Step complete

Create `models/marts/revenue/fct_ad_impressions.sql` as a regular table model first. Don't worry about incremental yet - you'll explore the data in Step 8 and convert it in Step 9.

The fact table should be at the **impression grain** (one row per `(campaign_id, content_id, impression_date)`) and enrich each impression with attributes from `stg_ads__campaigns` (e.g. `campaign_type`, `advertiser_id`). Marts default to `materialized: table` via `dbt_project.yml`, so no `config()` block is needed yet.

??? tip "Hint: Skeleton"
    ```sql
    with impressions as (
        select * from {{ ref('stg_ads__impressions') }}
    ),

    campaigns as (
        select * from {{ ref('stg_ads__campaigns') }}
    ),

    final as (
        select
            i.impression_id,
            i.campaign_id,
            i.content_id,
            i.impression_date,
            i.impressions_count,
            i.clicks,
            i.click_through_rate,
            c.campaign_type,
            c.advertiser_id
            -- ... other useful campaign attributes
        from impressions i
        join campaigns c using (campaign_id)
    )

    select * from final
    ```

Run it once and confirm the row count matches `stg_ads__impressions`:

```bash
dbt run --select fct_ad_impressions
```

---

## Step 8 - Explore the data to choose an incremental strategy

- [ ] Step complete

Before turning Step 7's model into an incremental, you need three answers from the data. Work them out by querying `stg_ads__impressions` (or the table you just built) and write your conclusions down - you'll plug them into the config in Step 9.

**1. Unique key.** Which column (or combination of columns) uniquely identifies a row in this table? An incremental run needs to know what counts as "the same row" so it can decide whether to insert or update.

**2. High-watermark column.** When new data lands tomorrow, which column tells you "this is new"? You're looking for a column where the value always goes *up* over time (a date or timestamp is the usual candidate) - that way the model can simply filter "give me rows newer than the newest one I already have" instead of re-scanning everything.

**3. Update potential - the part that drives your strategy.** Each row in `stg_ads__impressions` is a finalized daily-aggregated total: once yesterday's impressions and clicks for `(cmp_001, art_002, 2024-01-16)` are recorded, that row doesn't change. New impression dates simply add new rows to the table.

If existing rows never change, you don't need to upsert them - you only ever **add** new ones. That points squarely at one strategy. Which one is the cheapest, simplest option that just adds new rows without touching what's already there?

??? tip "Hint: Useful queries"
    For (1) - check whether candidate keys are actually unique. Any rows returned = not unique:

    ```sql
    select <candidate_key>, count(*) as cnt
    from {{ ref('stg_ads__impressions') }}
    group by 1
    having count(*) > 1;
    ```

    Try this with `impression_id` first, then try the composite `(campaign_id, content_id, impression_date)`.

    For (2) - look at the spread and cardinality of date-like columns to spot a monotonically-increasing watermark:

    ```sql
    select min(<date_column>), max(<date_column>), count(distinct <date_column>)
    from {{ ref('stg_ads__impressions') }};
    ```

    For (3) - no query will tell you this; it's a design decision. Ask: "If a correction landed tomorrow for a row I already loaded, would I want my incremental model to pick it up?"

??? tip "Hint: How the answers map to config"
    - **Q1 → the grain you'll guard against duplicates in**. With `append`, dbt doesn't use a `unique_key` - knowing the grain just helps you reason about whether your `is_incremental()` filter is safe (i.e. whether it could ever pull a row you've already inserted).
    - **Q2 → the column you filter on** inside `{% if is_incremental() %}`, typically `where <column> > (select max(<column>) from {{ this }})`.
    - **Q3 → `incremental_strategy`**:
        - **`append`**: fastest and simplest - just inserts new rows. Right choice when existing rows never change.
        - **`merge`**: upserts on `unique_key`. Use when existing rows can be updated and you need those updates reflected.
        - **`insert_overwrite`**: deletes and rewrites a partition. Good for very large tables with clear partition boundaries (e.g. by month).

        For `fct_ad_impressions`, rows are finalized once they land, so `append` is the natural fit.

---

## Step 9 - Convert `fct_ad_impressions` to an incremental model

- [ ] Step complete

Now apply what you learned in Step 8. Add a `config()` block that overrides the default `table` materialization with `incremental` and sets `incremental_strategy` from your answer. Then add an `{% if is_incremental() %}` filter that limits the rows processed on subsequent runs.

Browse the dbt docs on [incremental models](https://docs.getdbt.com/docs/build/incremental-models) and [`is_incremental()`](https://docs.getdbt.com/docs/build/incremental-models#understanding-the-is_incremental-macro) if you need a refresher on the exact config keys.

??? tip "Hint: Where each piece goes"
    Use `{{ this }}` inside the incremental branch - it resolves to the existing version of the model you're building, so you can subselect `max(<watermark>)` from it.

    ```sql
    {{
        config(
            materialized='incremental',
            incremental_strategy='...'
        )
    }}

    with impressions as (
        select * from {{ ref('stg_ads__impressions') }}

        {% if is_incremental() %}
            where <watermark_column> > (select coalesce(max(<watermark_column>), '1900-01-01') from {{ this }})
        {% endif %}
    ),

    -- ... rest of the model unchanged from Step 7
    ```

Run it twice and compare row counts to confirm incremental behaviour:

```bash
dbt run --select fct_ad_impressions
dbt run --select fct_ad_impressions  -- second run: should process zero new rows
```

---

## Step 10 - Understand incremental trade-offs

- [ ] Step complete

Discuss with your group:

1. Why did `append` fit `fct_ad_impressions`, and what kind of upstream change would force you to switch to `merge`?
2. Your high-watermark filter is `impression_date > max(impression_date)`. What's the gotcha if a late row for *yesterday* arrives *after* you've already loaded a row for *today*?
3. When would you reach for `--full-refresh`?

??? tip "Hint: Key considerations"
    - **`append` vs `merge`**: as long as a row in `stg_ads__impressions` is finalized when it first lands, `append` is fine. The day the upstream system starts re-emitting corrections to existing `(campaign_id, content_id, impression_date)` rows, `append` would create duplicates and you'd need `merge` (with the same `unique_key`).
    - **High-watermark gotcha**: a strict `>` filter on the max date drops any row whose date is `<=` what you've already loaded - so a delayed yesterday-row that arrives after a today-row is silently skipped. To handle that you'd need to switch to `merge` (with a `unique_key`) and widen the filter to a "look-back window" (e.g. `where impression_date >= dateadd('day', -3, (select max(impression_date) from {{ this }}))`). With pure `append`, widening the filter would just create duplicates.
    - **`--full-refresh`** rebuilds the whole table from scratch. Reach for it when: schema changes, logic changes that affect historical rows, or you suspect data drift in already-loaded partitions.

---

## Step 11 - BONUS: Run `dbt build` on your staging models

- [ ] Step complete

```bash
dbt build --select staging.ads
```

Fix any source test failures. Then open the lineage graph and confirm all three staging models appear with green source nodes from `ads`.

---

## Step 12 - BONUS: Write your own `cents_to_dollars` macro

- [ ] Step complete

You repeated the same `(<col> / 100.0)::numeric(...)` expression in `stg_ads__campaigns`, `stg_ads__spend`, and anywhere else there's a `_cents` column. That's a copy-paste begging to be a macro.

Create `macros/cents_to_dollars.sql` that takes a column name (and optionally a scale) and returns the conversion expression. Then refactor your staging models to call it:

```sql
{{ cents_to_dollars('budget_cents') }} as budget_dollars
```

Re-run the affected staging models and confirm the output is identical to before the refactor.

??? tip "Hint: Macro skeleton"
    Macros live in `macros/<name>.sql` and use Jinja's `{% macro %} ... {% endmacro %}` block. Arguments are referenced inside the block with `{{ arg_name }}`.

    ```sql
    {% macro cents_to_dollars(column_name, scale=2) %}
        ({{ column_name }} / 100.0)::numeric(16, {{ scale }})
    {% endmacro %}
    ```

    Browse the [dbt docs on macros](https://docs.getdbt.com/docs/build/jinja-macros) if you want to see what else Jinja can do here.

---

!!! success "Done?"
    You've defined sources, built three staging models, loaded a commission seed, and built an incremental fact table. The hardest part - understanding *why* incremental works the way it does - is done.

    Now head to [Level 2](../level2/checklist.md) to build the revenue mart, add snapshots, and write custom SQL assertions!

