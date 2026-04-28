# Group 3 - Checklist

Work through the steps in order. This track requires the most technical depth - if you're stuck on an incremental concept, re-read the [Overview](overview.md) before expanding a hint.

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
            lower(trim(campaign_type))              as campaign_type,
            cast(start_date as date)                as start_date,
            cast(end_date as date)                  as end_date,
            budget_cents / 100.0                    as budget_dollars
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
            cast(spend_date as date)             as spend_date,
            spend_cents / 100.0                  as spend_dollars,
            platform_fee_cents / 100.0           as platform_fee_dollars,
            (spend_cents - platform_fee_cents) / 100.0 as net_spend_dollars
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
dbt run --select fct_ad_impressions  # second run - should process fewer rows
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

## Step 9 - Build `revenue_by_content.sql`

- [ ] Step complete

Create `models/marts/revenue/revenue_by_content.sql`. This mart allocates ad spend to content items proportionally based on impression share.

!!! warning "Check the existing model first"
    Open `models/marts/revenue/revenue_by_content.sql`. The model aggregates spend at `campaign_id` grain - this loses the per-content breakdown. Understand the grain problem, then rewrite it.

??? tip "Hint: Allocation logic"
    ```sql
    with impressions as (
        select
            campaign_id,
            content_id,
            impression_date,
            impressions_count
        from {{ ref('fct_ad_impressions') }}
    ),

    campaign_totals as (
        select
            campaign_id,
            impression_date,
            sum(impressions_count) as total_campaign_impressions
        from impressions
        group by 1, 2
    ),

    impression_share as (
        select
            i.campaign_id,
            i.content_id,
            i.impression_date,
            i.impressions_count,
            ct.total_campaign_impressions,
            i.impressions_count / nullif(ct.total_campaign_impressions, 0) as impression_share
        from impressions i
        join campaign_totals ct using (campaign_id, impression_date)
    ),

    spend as (
        select campaign_id, spend_date, spend_dollars, net_spend_dollars
        from {{ ref('stg_ads__spend') }}
    ),

    allocated as (
        select
            is_.content_id,
            is_.impression_date,
            is_.campaign_id,
            c.campaign_type,
            is_.impression_share * s.spend_dollars      as allocated_spend_dollars,
            is_.impression_share * s.net_spend_dollars  as allocated_net_spend_dollars
        from impression_share is_
        join spend s
            on is_.campaign_id   = s.campaign_id
            and is_.impression_date = s.spend_date
        join {{ ref('stg_ads__campaigns') }} c using (campaign_id)
    ),

    with_commission as (
        select
            a.*,
            cl.commission_rate,
            a.allocated_net_spend_dollars * cl.commission_rate as mediapulse_revenue_dollars
        from allocated a
        left join {{ ref('commission_lookup') }} cl using (campaign_type)
    )

    select * from with_commission
    ```

---

## Step 10 - Create a snapshot for advertiser campaign budgets

- [ ] Step complete

Create `snapshots/snap_ads__campaigns.sql`. Track budget changes using the `timestamp` strategy - campaigns can have their budgets modified after launch.

??? tip "Hint"
    ```sql
    {% snapshot snap_ads__campaigns %}

    {{
        config(
            target_schema='snapshots',
            unique_key='campaign_id',
            strategy='timestamp',
            updated_at='updated_at',   -- check if this column exists; use check strategy if not
        )
    }}

    select
        campaign_id,
        advertiser_id,
        campaign_name,
        campaign_type,
        budget_cents,
        start_date,
        end_date
    from {{ source('ads', 'campaigns') }}

    {% endsnapshot %}
    ```

    If `ads.campaigns` has no `updated_at` column, switch to the `check` strategy:

    ```sql
    config(
        strategy='check',
        check_cols=['budget_cents', 'end_date'],
        ...
    )
    ```

---

## Step 11 - Write singular test: revenue does not exceed spend

- [ ] Step complete

Create `tests/assert_revenue_lte_spend.sql`. For each `(campaign_id, impression_date)`, allocated revenue should never exceed gross spend.

??? tip "Hint"
    ```sql
    -- Fails (returns rows) if allocated revenue exceeds gross spend for any campaign/day
    select
        campaign_id,
        impression_date,
        sum(allocated_spend_dollars)    as total_allocated,
        max(spend_dollars)              as gross_spend
    from {{ ref('revenue_by_content') }}
    group by 1, 2
    having sum(allocated_spend_dollars) > max(spend_dollars) * 1.001  -- 0.1% tolerance for float rounding
    ```

---

## Step 12 - Write singular test: no negative spend

- [ ] Step complete

Create `tests/assert_no_negative_spend.sql`. Negative values in `stg_ads__spend` indicate a data pipeline issue upstream.

??? tip "Hint"
    ```sql
    select spend_id, spend_date, spend_dollars
    from {{ ref('stg_ads__spend') }}
    where spend_dollars < 0
       or net_spend_dollars < 0
    ```

---

## Step 13 - Add YAML for staging models and the mart

- [ ] Step complete

Create `models/staging/ads/_ads__models.yml` and `models/marts/revenue/_revenue__models.yml`. Document columns and add tests.

Include a `relationships` test on `fct_ad_impressions.campaign_id` → `stg_ads__campaigns.campaign_id`.

??? tip "Hint: Relationships test"
    ```yaml
    - name: campaign_id
      data_tests:
        - not_null
        - relationships:
            to: ref('stg_ads__campaigns')
            field: campaign_id
    ```

---

## Step 14 - Run `dbt build --select +revenue_by_content`

- [ ] Step complete

```bash
dbt build --select +revenue_by_content
```

This builds the full lineage - sources → staging → incremental fact → mart - and runs all tests. Fix any failures.

??? tip "Hint: If the revenue test fails"
    A failure in `assert_revenue_lte_spend` usually means the impression share doesn't sum to exactly 1.0 for all campaigns on all days (floating point rounding or gaps between impressions and spend records). Add a `nullif` guard and a small tolerance:

    ```sql
    having sum(allocated_spend_dollars) > max(spend_dollars) * 1.001
    ```

---

## Step 15 - BONUS: Test the incremental model more rigorously

- [ ] Step complete

Write a singular test that verifies no `impression_id` appears more than once in `fct_ad_impressions`:

```sql
-- tests/assert_no_duplicate_impression_ids.sql
select impression_id, count(*) as cnt
from {{ ref('fct_ad_impressions') }}
group by 1
having count(*) > 1
```

!!! success "Done?"
    You've built the revenue spine of the MediaPulse data platform. Group 4 will use dbt-expectations to add statistical guardrails around these models - share your mart YAML with them so they can build on it.

