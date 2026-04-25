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
- package: calogica/dbt_expectations
  version: [">=0.10.0", "<1.0.0"]
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
3. Set `severity: error` on the `relationships` test linking `fct_ad_impressions.campaign_id` → `stg_ads__campaigns` - a broken FK here means revenue is being allocated to campaigns that don't exist, which is a hard data error.

??? tip "Hint: Test config syntax"
    ```yaml
    - name: campaign_type
      data_tests:
        - accepted_values:
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
            to: ref('stg_ads__campaigns')
            field: campaign_id
            config:
              severity: error
    ```

---

## Step 3 - Enable `store_failures` on a revenue test

- [ ] Step complete

Revenue tests that fail are always worth investigating row-by-row. Enable `store_failures` on your `assert_revenue_lte_spend` singular test by adding a config block at the top of the file:

```sql
{{ config(store_failures=true, limit=200) }}

-- Fails (returns rows) if allocated revenue exceeds gross spend for any campaign/day
select
    campaign_id,
    impression_date,
    ...
```

Run it:

```bash
dbt test --select assert_revenue_lte_spend
```

Then query the failures table. Even if the test passes, confirm the failures table exists and is empty - that's proof the test ran correctly.

??? tip "Hint: store_failures in singular tests"
    For singular tests (`.sql` files in `tests/`), add the config macro at the top of the file:

    ```sql
    {{ config(store_failures=true, limit=200) }}
    ```

    For generic tests in YAML, use the `config:` block nested under the test definition.

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
              min_value: 20
        columns:
          - name: click_through_rate
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0.0
                  max_value: 1.0
                  config:
                    severity: error
          - name: impressions_count
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
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
              min_value: 10
        columns:
          - name: mediapulse_revenue_dollars
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0
                  config:
                    severity: error
          - name: impression_share
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0.0
                  max_value: 1.0
                  config:
                    severity: warn
    ```

---

## Step 6 - Run the full test suite and review severity split

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
