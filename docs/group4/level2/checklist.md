# Group 4 - Checklist Level 2

## dbt Mesh: Cross-project References and Infrastructure

Start on this checklist once you have completed [Level 1](../level1/checklist.md).

In this level you will:

- **Wire cross-project references** in `mediapulse_analytics` to consume the contracted platform models
- **Fix the mart bugs** that become visible once cross-project refs are in place
- **Verify** the full two-project pipeline runs end to end

---

## Step 1 - Understand what the analytics project needs

- [ ] Step complete

Open `mediapulse_analytics/models/marts/` and audit both mart models. For each model:

- Which staging models does it `ref()`?
- Which of those models now lives in `mediapulse_platform`?
- Which can stay as local `ref()` calls (if any analytics-only staging models exist)?

List the specific `ref()` calls that need to become cross-project refs.

---

## Step 2 - Update `fct_content_performance.sql` to use cross-project refs

- [ ] Step complete

Open `models/marts/content/fct_content_performance.sql` and update every reference to a platform staging model to use the cross-project ref syntax:

```sql
{{ ref('mediapulse_platform', 'stg_news__articles') }}
```

While you are in this file, fix the logic bug: the model uses `INNER JOIN` between articles and episodes on `category`, which produces a cross-join explosion. The correct approach is `UNION ALL` after normalising both to a common schema. See the [analytics project overview](../../mediapulse/analytics-overview.md) for the bug description.

Run the fixed model:

```bash
dbt run --select fct_content_performance
```

Confirm the row count is articles + episodes, not a Cartesian product.

---

## Step 3 - Update `fct_ad_revenue.sql` to use cross-project refs

- [ ] Step complete

Open `models/marts/revenue/fct_ad_revenue.sql` and update all platform staging model references to cross-project refs.

Also fix the grain bug: the model currently groups at `campaign_id` grain. Rewrite it to produce one row per `(campaign_id, content_id, impression_date)`, allocating spend proportionally by impression share.

Run and verify:

```bash
dbt run --select fct_ad_revenue
```

---

## Step 4 - Create the commission lookup seed

- [ ] Step complete

Create `seeds/commission_lookup.csv` in `mediapulse_analytics`:

```
campaign_type,commission_rate
display,0.15
video,0.20
sponsored_content,0.25
podcast_ad,0.18
newsletter,0.12
```

Load it with `dbt seed`, then update `fct_ad_revenue.sql` to join this seed and derive `mediapulse_revenue_dollars`.

---

## Step 5 - Run the full end-to-end build

- [ ] Step complete

Run the platform project first, then the analytics project:

```bash
# In mediapulse_platform:
dbt build

# In mediapulse_analytics:
dbt build
```

All models should pass. A cross-project ref failure at this stage usually means either the platform model is not marked `public` or the `dependencies.yml` in the analytics project does not match the platform project name.

??? tip "Hint: debugging cross-project ref failures"
    Check three things in order:
    1. The platform model has `access: public` in its YAML.
    2. The platform project has been built and its manifest is accessible.
    3. The project name in `dependencies.yml` exactly matches the `name:` field in the platform's `dbt_project.yml`.

---

## Step 6 - Consider model versioning

- [ ] Step complete

Now that `mediapulse_platform` exposes public contracted models, changing a column name or type is a breaking change for `mediapulse_analytics`.

Read the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access) section on model versions.

Discuss with your group:

- When would you version a public model vs. just make the breaking change?
- How would the analytics team pin to a specific version of a platform model during a migration?
- Who is responsible for deprecating old versions?

There is no code to write for this step. The goal is to understand the governance trade-offs.

---

## Step 7 - CAPSTONE: design and build `fct_campaign_daily_performance`

- [ ] Step complete

The revenue domain has two facts so far: `fct_ad_revenue` (content x campaign x date, from Step 3) and the underlying `int_campaign_content_spend_allocation` (campaign x content). Neither answers the simplest question a media buyer asks first: "how is this campaign doing, day by day?" Build the mart that answers it.

Create `models/marts/revenue/fct_campaign_daily_performance.sql` in `mediapulse_analytics`.

Grain: one row per `(campaign_id, date)` - a coarser rollup than `fct_ad_revenue`, with no content breakdown.

Use cross-project refs to the platform project throughout, the same way you did in Steps 2-3:

- `impressions_count` and `clicks`, summed by day, from `{{ ref('mediapulse_platform', 'stg_ads__impressions') }}`
- `spend_cents` and `platform_fee_cents`, summed by day, from `{{ ref('mediapulse_platform', 'stg_ads__spend') }}`
- `campaign_name` and `campaign_type` from `{{ ref('mediapulse_platform', 'dim_campaigns') }}` (already built for you - a small preview of what a finished, contracted platform dim looks like)

Derive `spend_dollars` and `net_spend_dollars` (spend minus platform fee, in dollars) as part of the mart, the same conversion pattern you have already used for `fct_ad_revenue`.

??? tip "Hint: two source tables, two grains, one join key"
    `stg_ads__impressions` and `stg_ads__spend` are both already at daily grain per campaign - they just don't share a table. Aggregate each to `(campaign_id, date)` in its own CTE, then join them on that composite key before bringing in `dim_campaigns`. A `full outer join` (or `coalesce`-guarded `left join`s from a unioned date/campaign spine) protects you from silently dropping days that have spend but no impressions, or vice versa.

Decide whether this new mart should be documented and tested the same way you are governing the platform's public models - what would a downstream BI tool expect from a model like this? Run and test it:

```bash
dbt build --select fct_campaign_daily_performance
```

---

## Step 8 - BONUS: Add a campaign budget snapshot

- [ ] Step complete

Create `snapshots/snap_ads__campaigns.yml` in `mediapulse_analytics`. Track budget changes on campaigns over time using the `check` strategy (there is no `updated_at` column on `ads.campaigns`).

Read the [snapshots documentation](https://docs.getdbt.com/docs/build/snapshots) for the YAML syntax.

Run the snapshot and query the output to confirm the SCD Type 2 columns are populated correctly.

---

!!! success "Done?"
    You have wired the two projects together using dbt mesh cross-project refs, fixed both mart bugs, verified the full pipeline runs end to end, and designed the revenue domain's daily campaign rollup fact.

    Head to [Level 3](../level3/checklist.md) for CI/CD pipeline design and bonus topics!
