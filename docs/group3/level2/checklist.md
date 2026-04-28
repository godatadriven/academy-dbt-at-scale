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

## Step 1 - Build `revenue_by_content.sql`

- [ ] Step complete

Create `models/marts/revenue/revenue_by_content.sql`. This mart allocates ad spend to content items proportionally based on impression share.

!!! warning "Check the existing stub first"
    Open `models/marts/revenue/revenue_by_content.sql`. The stub aggregates spend at `campaign_id` grain - this loses the per-content breakdown. Understand the grain problem, then rewrite it.

??? tip "Hint: What's wrong with the stub"
    The stub groups by `campaign_id, campaign_name, campaign_type, advertiser_id` - there is no `content_id` in the `GROUP BY`. This means you get one row per campaign per day, not one row per content item per campaign per day. The mart is named "by content" but doesn't actually break down by content.

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
            s.spend_dollars,
            s.net_spend_dollars,
            is_.impression_share * s.spend_dollars     as allocated_spend_dollars,
            is_.impression_share * s.net_spend_dollars as allocated_net_spend_dollars
        from impression_share is_
        join spend s
            on is_.campaign_id    = s.campaign_id
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

## Step 2 - Create a snapshot for advertiser campaign budgets

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
            updated_at='updated_at',
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

## Step 3 - Write singular test: revenue does not exceed spend

- [ ] Step complete

Create `tests/assert_revenue_lte_spend.sql`. For each `(campaign_id, impression_date)`, allocated revenue should never exceed gross spend.

??? tip "Hint: When does a dbt test pass?"
    A test **passes** when the query returns **zero rows** - any rows returned are failures.

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

    Run it:

    ```bash
    dbt test --select assert_revenue_lte_spend
    ```

---

## Step 4 - Write singular test: no negative spend

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

## Step 5 - Add YAML for staging models and the mart

- [ ] Step complete

Create `models/staging/ads/_ads__models.yml` and `models/marts/revenue/_revenue__models.yml`. Document columns and add tests.

Include at minimum:

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

??? tip "Hint: Use codegen to scaffold the YAML"

    [dbt-codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/) generates model YAML so you don't have to write it by hand. If you installed it back in Level 1 Step 6, you're already set; otherwise add it to `packages.yml` and run `dbt deps`.

    **Option A - compile in an untitled file:** open an untitled file in dbt Cloud, paste the following, and click `</>` **Compile**:

    ```sql
    {{ codegen.generate_model_yaml(
        model_names=["stg_ads__campaigns", "stg_ads__spend", "stg_ads__impressions", "fct_ad_impressions", "revenue_by_content"]
    ) }}
    ```

    **Option B - use `dbt run-operation`:** prefer this if you'd rather stay on the command line. It prints the same YAML to stdout:

    ```bash
    dbt run-operation generate_model_yaml --args '{"model_names": ["stg_ads__campaigns", "stg_ads__spend", "stg_ads__impressions", "fct_ad_impressions", "revenue_by_content"]}'
    ```

    Either way: paste the output into your YAML files, then fill in descriptions and add any additional tests (including the `accepted_values` and `relationships` ones above).

---

## Step 6 - Run `dbt build --select +revenue_by_content`

- [ ] Step complete

```bash
dbt build --select +revenue_by_content
```

This builds the full lineage - sources → staging → incremental fact → mart - and runs all tests. Fix any failures.

??? tip "Hint: If the revenue test fails"
    A failure in `assert_revenue_lte_spend` usually means the impression share doesn't sum to exactly 1.0 for all campaigns on all days (floating point rounding or gaps between impressions and spend records). The `* 1.001` tolerance in the test handles minor float rounding - if it still fails, look at campaigns where impressions exist but no matching spend row exists for that date.

---

## Step 7 - BONUS: Test the incremental model more rigorously

- [ ] Step complete

Write a singular test that verifies no `impression_id` appears more than once in `fct_ad_impressions`:

```sql
-- tests/assert_no_duplicate_impression_ids.sql
select impression_id, count(*) as cnt
from {{ ref('fct_ad_impressions') }}
group by 1
having count(*) > 1
```

Run `dbt build --full-refresh --select fct_ad_impressions` followed by a second incremental run, and confirm the dedup test passes both times.

---

!!! success "Done?"
    You've built the revenue spine of the MediaPulse data platform - a correct-grain mart, a campaign budget snapshot, and custom SQL assertions that verify revenue integrity.

    Group 4 will use `dbt-expectations` to add statistical guardrails around these models. Share your mart YAML with them so they can build on it.

    Now head to [Level 3](../level3/checklist.md) to configure your tests with severity, `where` clauses, and `dbt_expectations` guardrails on your revenue models!

