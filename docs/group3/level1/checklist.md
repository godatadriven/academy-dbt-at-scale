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

Create `models/staging/ads/stg_ads__campaigns.sql`. Rename columns, convert budget to dollars, and lowercase `campaign_type`.

??? tip "Hint: Starter template"
    ```sql
    with source as (
        select * from {{ source('ads', 'campaigns') }}
    ),

    renamed as (
        select
            campaign_id,
            advertiser_id,
            campaign_name,
            lower(trim(campaign_type))          as campaign_type,
            cast(start_date as date)            as start_date,
            cast(end_date as date)              as end_date,
            budget_cents / 100.0               as budget_dollars
        from source
    )

    select * from renamed
    ```

    If Group 1's `cents_to_dollars` macro is available in the project, use it:

    ```sql
    {{ cents_to_dollars('budget_cents') }} as budget_dollars
    ```

---

## Step 5 - Build `stg_ads__spend.sql`

- [ ] Step complete

Create `models/staging/ads/stg_ads__spend.sql`. This is a transactional table - do not deduplicate; each row is a distinct daily spend record.

??? tip "Hint"
    ```sql
    with source as (
        select * from {{ source('ads', 'spend') }}
    ),

    renamed as (
        select
            spend_id,
            campaign_id,
            cast(spend_date as date)                        as spend_date,
            spend_cents / 100.0                             as spend_dollars,
            platform_fee_cents / 100.0                      as platform_fee_dollars,
            (spend_cents - platform_fee_cents) / 100.0      as net_spend_dollars
        from source
    )

    select * from renamed
    ```

---

## Step 6 - Build `stg_ads__impressions.sql`

- [ ] Step complete

Create `models/staging/ads/stg_ads__impressions.sql`. Keep the daily grain - one row per `(campaign_id, content_id, impression_date)`.

??? tip "Hint"
    ```sql
    with source as (
        select * from {{ source('ads', 'impressions') }}
    ),

    renamed as (
        select
            impression_id,
            campaign_id,
            content_id,
            cast(impression_date as date)   as impression_date,
            impressions_count,
            clicks,
            case
                when impressions_count > 0
                then round(clicks / impressions_count::decimal, 4)
                else 0
            end                             as click_through_rate
        from source
    )

    select * from renamed
    ```

---

## Step 7 - Build `fct_ad_impressions.sql` as an incremental model

- [ ] Step complete

Create `models/marts/revenue/fct_ad_impressions.sql`. This is the high-volume fact table - it must be incremental to be practical.

Requirements:

- `materialized='incremental'`
- `unique_key='impression_id'`
- `incremental_strategy='merge'`
- The `is_incremental()` filter should only pick up rows where `impression_date >= max(impression_date)` in the current table

??? tip "Hint: Full incremental model"
    ```sql
    {{
        config(
            materialized='incremental',
            unique_key='impression_id',
            incremental_strategy='merge'
        )
    }}

    with impressions as (
        select * from {{ ref('stg_ads__impressions') }}
    ),

    campaigns as (
        select
            campaign_id,
            campaign_type,
            advertiser_id
        from {{ ref('stg_ads__campaigns') }}
    ),

    joined as (
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
        from impressions i
        left join campaigns c using (campaign_id)
    )

    select * from joined

    {% if is_incremental() %}
        where impression_date >= (select max(impression_date) from {{ this }})
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

