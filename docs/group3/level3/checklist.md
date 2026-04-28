# Group 3 - Checklist Level 3

## Advanced Testing

Start on this checklist once you have completed [Checklist Level 2](../level2/checklist.md).

In this level you will apply the following skills:

- **Test configuration** - `severity`, `where`, `store_failures`, `limit`
- **Package-based tests** - `dbt_expectations` for statistical guardrails on revenue models
- **Test strategy** - deciding what to test, at what severity, and why

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Install `dbt_expectations`

- [ ] Step complete

Add the package to `packages.yml`:

```yaml
- package: metaplane/dbt_expectations
  version: # check the current version on the dbt hub
```

Then install:

```bash
dbt deps
```

---

## Step 2 - Add `severity` and `where` to existing tests

- [ ] Step complete

Open `_ads__models.yml` and `_revenue__models.yml` and apply the following configuration:

1. Set `severity: warn` on the `accepted_values` test for `campaign_type` - new campaign types may be introduced and shouldn't hard-fail CI.
2. Add a `where` filter to the `not_null` test on `spend_dollars` in `stg_ads__spend` so it only evaluates rows where `spend_dollars > 0` (zero-spend rows are valid for paused campaigns).
3. Configure the `relationships` test linking `fct_ad_impressions.campaign_id` → `stg_ads__campaigns`. **You decide:** what severity is appropriate here, and why? Think about what a broken foreign key means for the revenue numbers downstream consumers will see, and what should happen in CI when it breaks. Be ready to defend your choice in the group discussion at the end of this level.

??? tip "Hint: Test config syntax"
    A `config:` block nested under a test changes its behaviour:

    ```yaml
    - name: campaign_type
      data_tests:
        - accepted_values:
            arguments:
              values: ['display', 'video', 'sponsored_content', 'podcast_ad', 'newsletter']
            config:
              severity: warn

    - name: spend_dollars
      data_tests:
        - not_null:
            config:
              where: "spend_dollars > 0"

    - name: campaign_id
      data_tests:
        - relationships:
            arguments:
              to: ref('stg_ads__campaigns')
              field: campaign_id
            config:
              severity: # your call
    ```

---

## Step 3 - Enable `store_failures` on a revenue test

- [ ] Step complete

Revenue tests that fail are always worth investigating row-by-row. Enable `store_failures` on your `assert_revenue_lte_spend` singular test, and cap the size of the resulting failures table with `limit`.

Read the dbt docs on the config and figure out exactly where it goes for a singular test (it's a slightly different shape than for a generic test in YAML):

- 📖 [`store_failures`](https://docs.getdbt.com/reference/resource-configs/store_failures?version=1.12)

Once configured, run it:

```bash
dbt test --select assert_revenue_lte_spend
```

Then query the failures table. Even if the test passes, confirm the failures table exists and is empty - that's proof the test ran correctly.

!!! note "Heads-up: dbt_expectations is needed from Step 4 onwards"
    The next steps lean on `dbt_expectations`. If you skipped Step 1, find the package on the [dbt package hub](https://hub.getdbt.com/) and add it to your `packages.yml`, then run `dbt deps` to install it.

---

## Step 4 - Add `dbt_expectations` tests to `fct_ad_impressions`

- [ ] Step complete

This is the highest-volume, most critical fact table. Add the following guardrails in `_revenue__models.yml`:

- The table should have at least 20 rows (catch a load failure)
- `impressions_count` should always be greater than 0
- `click_through_rate` should be between 0 and 1 - a CTR above 100% is physically impossible and indicates a calculation error
- `impression_date` should not be null

??? tip "Hint: CTR bounds"
    ```yaml
    models:
      - name: fct_ad_impressions
        data_tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              arguments:
                min_value: 20
        columns:
          - name: click_through_rate
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  arguments:
                    min_value: 0.0
                    max_value: 1.0
                  config:
                    severity: error
          - name: impressions_count
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  arguments:
                    min_value: 1
                  config:
                    severity: warn
    ```

---

## Step 5 - Add `dbt_expectations` tests to `revenue_by_content`

- [ ] Step complete

Add guardrails to the revenue mart:

- `mediapulse_revenue_dollars` should always be 0 or greater (revenue can't be negative)
- `allocated_spend_dollars` should be greater than 0 (zero-allocation rows indicate a join miss)
- `impression_share` should be between 0 and 1
- Add a row count lower bound

Set `mediapulse_revenue_dollars >= 0` as `severity: error` - negative revenue is a hard data error that must block CI.

??? tip "Hint"
    ```yaml
    models:
      - name: revenue_by_content
        data_tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              arguments:
                min_value: 10
        columns:
          - name: mediapulse_revenue_dollars
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  arguments:
                    min_value: 0
                  config:
                    severity: error
          - name: impression_share
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  arguments:
                    min_value: 0.0
                    max_value: 1.0
                  config:
                    severity: warn
    ```

---

## Step 6 - Stretch your test suite: what else would you cover?

- [ ] Step complete

You've now applied generic tests, singular tests, severity/`where` config, `store_failures`, and a handful of `dbt_expectations` checks. Step back and ask: **what else would you test on these models if this were a real production pipeline?**

Brainstorm with your group, then pick one or two extra tests to actually add. Some directions to consider:

- **Within `dbt_utils`** (already installed): tests like `expression_is_true`, `equal_rowcount`, `recency`, or `mutually_exclusive_ranges` cover things that pure `not_null` / `unique` won't.
- **Anomaly / freshness** - is the latest `impression_date` recent enough? Is yesterday's row count within 20% of the 7-day average?
- **Cross-model invariants** - does the sum of `allocated_spend_dollars` reconcile to total `spend_dollars` per day? (You partly tested this in Level 2 Step 3 - tighten the tolerance, or add the inverse check.)
- **Distribution shape** - `expect_column_quantile_values_to_be_between`, `expect_column_stdev_to_be_between` from `dbt_expectations`.

Other packages worth looking at on the [dbt package hub](https://hub.getdbt.com/):

- 📦 **[`elementary`](https://hub.getdbt.com/elementary-data/elementary/latest/)** - anomaly detection on volume, freshness, and column-level statistics out of the box.
- 📦 **[`dbt_project_evaluator`](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/)** - tests the *project itself* (model naming, missing tests, missing documentation) rather than the data.
- 📦 **[`dbt_meta_testing`](https://hub.getdbt.com/tnightengale/dbt_meta_testing/latest/)** - assert that every model has a minimum set of tests/docs.

Pick one or two ideas, add them to your YAML or `tests/` folder, and run them. Note what was easy vs awkward to express - test gaps usually live in that awkwardness.

---

## Step 7 - Run the full test suite and review severity split

- [ ] Step complete

```bash
dbt test --select staging.ads marts.revenue
```

Review and discuss:

- Which tests did you set as `error` vs `warn` - and what was your reasoning?
- The revenue tests are particularly high-stakes. Which ones would you make `error` that currently aren't?
- How would you communicate test failures to non-technical stakeholders? (A failing revenue assertion isn't just a dbt problem.)

As a group, draft a one-paragraph "test contract" for `revenue_by_content`: what guarantees does this model make to its consumers, and how does the test suite enforce those guarantees?

---

!!! success "Done?"
    You've moved from writing tests to *configuring* them - choosing severity, scoping with `where`, storing failures for debuggability, and adding statistical guardrails around your revenue models. A well-configured test suite is the difference between a pipeline that fails loudly and one that silently serves wrong numbers.
