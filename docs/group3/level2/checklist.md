# Group 3 - Checklist Level 2

## Multi-project Workflows: Contracts, Groups, and Cross-project Refs

Start on this checklist once you have completed [Level 1](../level1/checklist.md).

In this level you will:

- **Add model contracts** and access controls to `mediapulse_platform`
- **Create groups** to organise models by domain
- **Define exposures** to document what downstream tools consume
- **Wire cross-project references** in `mediapulse_analytics`

---

## Step 1 - Decide what to expose publicly

- [ ] Step complete

Before writing any YAML, answer as a group:

1. Which models in `mediapulse_platform` does `mediapulse_analytics` need to reference? Those are `public` candidates.
2. Which models are internal helpers and should stay `protected`?
3. Are there any models that should be restricted to a single domain group?

Read the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access) before deciding.

---

## Step 2 - Create domain groups in the platform project

- [ ] Step complete

Define at least one group per source domain (news, podcasts, streaming, ads) in `mediapulse_platform`. Read the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access) for the YAML syntax.

Assign each staging model to its domain group.

---

## Step 3 - Add model contracts to the public models

- [ ] Step complete

For each model you decided to expose publicly, add:

- `access: public` in the model YAML
- `config.contract.enforced: true`
- A `data_type` for every column (contracts require full column coverage)

Read the [model contracts documentation](https://docs.getdbt.com/docs/mesh/govern/model-contracts) for the full syntax.

!!! warning "Contracts require full column coverage"
    Every column produced by the model must be listed in the YAML with a `data_type`. Use codegen to generate the full column list:

    ```bash
    dbt run-operation generate_model_yaml --args '{"model_names": ["stg_news__articles"]}'
    ```

Test that the contracts run correctly:

```bash
dbt run --select stg_news__articles stg_news__authors stg_podcasts__episodes stg_podcasts__shows
```

---

## Step 4 - Define exposures for key downstream consumers

- [ ] Step complete

Exposures document what downstream tools (BI dashboards, notebooks, ML pipelines) consume from the platform. Add at least one exposure for a hypothetical BI tool that queries the content and revenue data.

Read the [exposures documentation](https://docs.getdbt.com/docs/build/exposures) for the YAML syntax.

After adding the exposure, regenerate and view the docs:

```bash
dbt docs generate && dbt docs serve
```

Confirm the exposure appears in the lineage graph and shows the full upstream dependency chain.

---

## Step 5 - Wire cross-project references in `mediapulse_analytics`

- [ ] Step complete

Switch to the `mediapulse_analytics` project. Open `models/marts/content/fct_content_performance.sql`.

The model currently uses `ref('stg_news__articles')`, which only works within the same project. Update it to use the cross-project ref syntax:

```sql
{{ ref('mediapulse_platform', 'stg_news__articles') }}
```

Do the same for all staging model references in the mart. You will also need to fix the logic bug (the model uses `INNER JOIN` instead of `UNION ALL`). See the [MediaPulse analytics overview](../../mediapulse/analytics-overview.md) for the bug description.

After updating, run the model:

```bash
dbt run --select fct_content_performance
```

??? tip "Hint: the dependencies.yml file"
    The `dependencies.yml` file in `mediapulse_analytics` already declares `mediapulse_platform` as an upstream project. This is what enables cross-project refs. If dbt cannot resolve the ref, confirm that the platform project has been built and that its manifest is available to the analytics project.

---

## Step 6 - Build and fix `fct_ad_revenue.sql`

- [ ] Step complete

Open `models/marts/revenue/fct_ad_revenue.sql`. The model aggregates at `campaign_id` grain, but the mart is named "by content". Fix the grain: the output should have one row per `(campaign_id, content_id, impression_date)`.

Update all staging `ref()` calls to cross-project refs at the same time.

Run and verify:

```bash
dbt run --select fct_ad_revenue
```

Confirm the row count matches what you would expect at impression grain.

---

## Step 7 - Create the commission lookup seed

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

Load it:

```bash
dbt seed --select commission_lookup
```

Update `fct_ad_revenue.sql` to join on this seed using `{{ ref('commission_lookup') }}` and add the derived `mediapulse_revenue_dollars` column.

Read the [seeds documentation](https://docs.getdbt.com/docs/build/seeds) if needed.

---

## Step 8 - Create a campaign budget snapshot

- [ ] Step complete

Create `snapshots/snap_ads__campaigns.yml` in `mediapulse_analytics`. The snapshot should track budget changes on campaign records over time.

Decide:

- `unique_key`: which column identifies a campaign?
- `strategy`: is there an `updated_at` column on `ads.campaigns`? If not, use the `check` strategy and list the columns that can change.
- Which columns should be monitored for changes (`budget_cents`, `end_date`, `campaign_type`)?

Read the [snapshots documentation](https://docs.getdbt.com/docs/build/snapshots) for the YAML syntax.

Run the snapshot and query the output table:

```bash
dbt snapshot --select snap_ads__campaigns
```

---

## Step 9 - Write singular tests for the revenue mart

- [ ] Step complete

Create two singular tests in `mediapulse_analytics/tests/`:

1. `assert_revenue_not_null.sql`: every row in `fct_ad_revenue` should have a non-null `mediapulse_revenue_dollars`. A null means allocated spend cannot be attributed to revenue.
2. `assert_no_negative_spend.sql`: no row in the revenue mart should have a negative `allocated_spend_dollars`.

A singular test passes when the query returns zero rows.

Run them:

```bash
dbt test --select assert_revenue_not_null assert_no_negative_spend
```

---

## Step 10 - CAPSTONE: design and build `fct_ad_impressions`

- [ ] Step complete

The ads domain has staging models and an intermediate spend allocation, but no governed fact table of its own - `int_campaign_content_spend_allocation` is a view, not a public, contracted mart. Promote it into one: `fct_ad_impressions`.

Create `models/marts/ads/fct_ad_impressions.sql` in `mediapulse_platform`.

Grain: one row per `(campaign_id, content_id, impression_date)` - the same grain `stg_ads__impressions` is already at.

A reasonable core scope:

- `campaign_id`, `content_id`, `impression_date`, `impressions_count`, `clicks` from `stg_ads__impressions`
- `campaign_type` and `campaign_name` from `dim_campaigns` (already built for you in `models/marts/`)
- A computed `click_through_rate` (`clicks / impressions_count`, guarding against divide-by-zero)

??? tip "Stretch: bring in allocated spend"
    `int_campaign_content_spend_allocation` already computes `allocated_spend_cents` per `(campaign_id, content_id)` - but at *no* date grain, since spend is only recorded at campaign level per day, not per content per day.

    Joining that model's `allocated_spend_cents` onto your date-grain fact means every impression-date for a given campaign/content pair gets the *same* total allocated spend, not a daily share of it. Decide: is that acceptable to ship with a documented caveat, or would you re-derive a daily allocation by distributing `int_campaign_content_spend_allocation`'s total proportionally across the content's impression-days within the campaign? There's no single right answer - defend whichever you choose.

Once you have decided whether to expose this model publicly (Step 1-3 above), apply the same access and contract config to it. Document it in a `_ads__marts.yml` file alongside `dim_campaigns`, with `not_null` tests on your grain columns. Run and test it:

```bash
dbt build --select fct_ad_impressions
```

---

!!! success "Done?"
    You have added model contracts and access controls to the platform project, wired the analytics project to consume platform models via cross-project refs, built out the revenue pipeline with a seed, snapshot, and singular tests, and promoted the ads domain's spend allocation logic into a governed fact table.

    Head to [Level 3](../level3/checklist.md) for CI/CD pipeline setup!
