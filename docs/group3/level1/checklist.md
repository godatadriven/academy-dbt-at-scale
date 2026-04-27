# Group 3 - Checklist Level 1

## dbt Fundamentals + Incremental Models

This track requires the most technical depth. If you're stuck on an incremental concept, re-read the [Overview](../overview.md) before expanding a hint.

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

- What is the grain of `impressions`? (one row per what?)
- Can a campaign appear in `spend` multiple times? When?
- What unit is `budget_cents` in? What about `spend_cents`?

??? tip "Hint: Grain analysis"
    - `campaigns`: one row per campaign (SCD-friendly - budget can change)
    - `impressions`: one row per `(campaign_id, content_id, impression_date)` - daily aggregate
    - `spend`: one row per `(campaign_id, spend_date)` - can have multiple rows per campaign as days accumulate; rows can also be *updated* retroactively

    All monetary values are in cents. You'll need a macro or inline calculation to convert.

---

## Step 2 - Define sources in YAML

- [ ] Step complete

Create `models/staging/ads/_ads__sources.yml`. Define a source named `ads` with all three tables, including `not_null` and `unique` tests on primary keys.

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
                data_tests: [not_null, unique]
          - name: impressions
            columns:
              - name: impression_id
                data_tests: [not_null, unique]
          - name: spend
            columns:
              - name: spend_id
                data_tests: [not_null, unique]
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
podcast_ad,0.18
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
    - Monetary values in the raw data aren't in the unit you'd want to report on. The `dbt_utils` package (already in `packages.yml`) ships a macro that handles this exact conversion - search the [dbt_utils docs](https://github.com/dbt-labs/dbt-utils) for the right one.
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
            -- {{ dbt_utils.<macro_name>('budget_cents') }} as budget_dollars
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

!!! tip "Use the **Generate model** button"
    Rather than typing the boilerplate by hand, in dbt Cloud you can right-click the source table in the file tree and choose **Generate model** - it scaffolds a staging model with all source columns selected. Then layer your transformations (rename, cast, derived metrics) on top. Same idea Group 2 used.

??? tip "Hint: Use codegen to scaffold the staging SQL"

    [dbt-codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/) can generate the boilerplate `select` for a staging model so you don't have to type every column by hand. You'll use this package again in Level 2 for YAML generation.

    **1. Add the package to `packages.yml`** by adding the following two lines under `dbt_utils`:

    ```yaml
    - package: dbt-labs/codegen
      version: 0.13.1
    ```

    **2. Install it:** It should automatically install, however to manually do this you can run the following in the command line.

    ```bash
    dbt deps
    ```

    **3. Open a new (or existing) untitled file in dbt Cloud and paste the following, then click `</>` **Compile**:**

    ```sql
    {{ codegen.generate_base_model(
        source_name='ads',
        table_name='impressions'
    ) }}
    ```

    Copy the compiled output into `stg_ads__impressions.sql` and layer your transformations (cast `impression_date`, derive `click_through_rate`) on top.

??? tip "Hint: Things to think about"
    - One row per `(campaign_id, content_id, impression_date)` - don't aggregate further.
    - For CTR: it's `clicks / impressions_count` *but* what should the value be when `impressions_count = 0`? `nullif` or a `case` statement both work.
    - Round CTR to a sensible number of decimal places so downstream consumers don't see noise.

---

## Step 7 - Build `fct_ad_impressions.sql` as an incremental model

- [ ] Step complete

Create `models/marts/revenue/fct_ad_impressions.sql`. This is the high-volume fact table - it must be incremental to be practical.

The model should be `materialized='incremental'` (full rebuilds on a high-volume fact table are not viable in production). Beyond that, you'll need to figure out the rest:

- Tell dbt how to identify each row so an incremental run knows what to upsert (which config key?).
- Pick a strategy - rows in upstream `spend` can be retroactively corrected, so *appending* would create duplicates. What strategy upserts instead?
- On subsequent runs, only process rows newer than what's already been built - look up which dbt config / built-in macros let you reference "the existing version of this model" inside the SQL.

Browse the dbt docs on [incremental models](https://docs.getdbt.com/docs/build/incremental-models) and [`is_incremental()`](https://docs.getdbt.com/docs/build/incremental-models#understanding-the-is_incremental-macro) - you'll need to figure out the correct config keys yourself.

??? tip "Hint: Skeleton to fill in"
    A staging-to-fact incremental model has three pieces: a `config()` block, a `with ... select` body that joins what you need from staging, and an `{% if is_incremental() %}` filter that limits the rows processed on incremental runs.

    Use `{{ this }}` inside the incremental branch - it resolves to the existing version of the model you're building, so you can subselect `max(impression_date)` (or whatever your high-watermark column is) from it.

    ```sql
    {{
        config(
            materialized='incremental',
            unique_key='...',
            incremental_strategy='...'
        )
    }}

    with impressions as (
        select * from {{ ref('stg_ads__impressions') }}
    ),

    -- join campaigns to attach campaign_type / advertiser_id

    final as (
        -- shape the row you want in the fact table
    )

    select * from final

    {% if is_incremental() %}
        -- only process rows newer than what's already in {{ this }}
    {% endif %}
    ```

Run it twice and compare row counts to confirm incremental behaviour:

```bash
dbt run --select fct_ad_impressions
dbt run --select fct_ad_impressions  -- second run: should process fewer rows
```

---

## Step 8 - Understand incremental trade-offs

- [ ] Step complete

Discuss with your group:

1. Why use `merge` over `append` here?
2. What happens if a spend row is retroactively corrected - does your incremental filter catch it?
3. When would you use `--full-refresh`?

??? tip "Hint: Key considerations"
    - **`append`**: fastest, but creates duplicates if source rows can be updated. Fine for immutable event streams.
    - **`merge`**: upserts on `unique_key`. Handles late-arriving or corrected data. Slightly slower.
    - **`insert_overwrite`**: deletes and rewrites a partition. Good for very large tables with clear partition boundaries (e.g., by month).

    The `spend` table updates retroactively - a `merge` strategy on `spend_id` handles this. The impressions table is append-only in practice, but using `merge` is safer.

    Use `--full-refresh` when: schema changes, logic changes that affect historical data, or you suspect data drift.

---

## Step 9 - BONUS: Run `dbt build` on your staging models

- [ ] Step complete

```bash
dbt build --select staging.ads
```

Fix any source test failures. Then open the lineage graph and confirm all three staging models appear with green source nodes from `ads`.

---

!!! success "Done?"
    You've defined sources, built three staging models, loaded a commission seed, and built an incremental fact table. The hardest part - understanding *why* incremental works the way it does - is done.

    Now head to [Level 2](../level2/checklist.md) to build the revenue mart, add snapshots, and write custom SQL assertions!

