# Group 1 - Checklist Level 3

## Advanced Testing

Start on this checklist once you have completed [Checklist Level 2](../level2/checklist.md).

In this level you will apply the following skills:

- **Test configuration** - `severity`, `where`, `store_failures`, `limit`
- **Package-based tests** - `dbt_expectations` for statistical guardrails
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

Test configuration lets you tune *how* a test fails and *which rows it applies to*. Open `_streaming__models.yml` and apply the following:

1. Set `severity: warn` on your `accepted_values` tests for `device_type` and `subscription_status` - these categories might legitimately expand and shouldn't block a CI run.
2. Add a `where` filter to the `unique` test on `watch_event_sk` to exclude any rows where `user_id is null` (anonymous sessions don't need uniqueness enforcement the same way).

??? tip "Hint: Test config syntax"
    Add a `config:` block nested inside any test to change its behaviour:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            values: [...]
            config:
              severity: warn  # or error (default)

        - unique:
            config:
              where: "column_name = 'some_value'"
    ```

    The `where` clause filters which rows the test evaluates - rows that don't match are skipped entirely.

---

## Step 3 - Enable `store_failures` on a test

- [ ] Step complete

`store_failures: true` tells dbt to write the failing rows to a table in your target schema instead of just reporting a pass/fail count. This makes it much easier to debug *which* rows failed and why.

Enable it on the `relationships` test linking `watch_events.content_id` → `stg_streaming__content_catalog.content_id`. Add a `limit` to cap how many failing rows are stored.

Run the test, then find and query the failures table in Snowflake. Does seeing the actual failing rows help you understand the problem faster than a row count alone?

??? tip "Hint: store_failures config"
    Add `store_failures` and `limit` inside a `config:` block on the test:

    ```yaml
    - relationships:
        to: ref('...')
        field: column_name
        config:
          store_failures: true
          limit: <n>
    ```

??? tip "Hint: Finding the failures table"
    After running with `store_failures: true`, dbt prints the table name in the run output:

    ```
    Stored N failures in: <schema>.<test_name>
    ```

    You can also use `store_failures_as: view` if you prefer a view that's refreshed on each run.

---

## Step 4 - Add `dbt_expectations` tests to `stg_streaming__watch_events`

- [ ] Step complete

Add statistical guardrails to the highest-volume model. In `_streaming__models.yml`, add the following model-level and column-level expectations:

- The table should have at least 10 rows (catch a silent truncation)
- `watch_duration_seconds` should always be greater than 0
- `watch_duration_seconds` should never exceed 86400 (24 hours - a sanity cap)
- `click_through_rate`-equivalent: there's no CTR here, but `device_type` after normalisation should only contain a known set of values (use `expect_column_distinct_values_to_be_in_set`)

??? tip "Hint: Model-level row count test"
    Row count tests go at the model level, not under a column:

    ```yaml
    - name: model_name
      data_tests:
        - dbt_expectations.expect_table_row_count_to_be_between:
            min_value: <n>
    ```

??? tip "Hint: Column value bounds"
    ```yaml
    - name: column_name
      data_tests:
        - dbt_expectations.expect_column_values_to_be_between:
            min_value: <n>
            max_value: <n>
    ```

    Think about what bounds would catch a genuine data quality issue - not just what happens to be in the current dataset.

??? tip "Hint: Distinct value set"
    ```yaml
    - name: column_name
      data_tests:
        - dbt_expectations.expect_column_distinct_values_to_be_in_set:
            value_set: ['val1', 'val2', ...]
    ```

    Unlike `accepted_values`, this operates on the set of *distinct* values rather than row by row - it passes even if some values in the set don't appear in the data.

---

## Step 5 - Add `dbt_expectations` tests to `stg_streaming__subscriptions`

- [ ] Step complete

Add guardrails to the subscriptions model:

- `monthly_fee_cents` should be 0 or greater (no negative fees)
- `monthly_fee_cents` should be 0 only when `subscription_status = 'trialing'`
- The table should have at least 5 rows

The second assertion requires a `where` clause - a fee of 0 on a non-trialing subscription is a data error.

??? tip "Hint: Scoping a test with where"
    You can limit which rows a `dbt_expectations` test evaluates using `config.where`:

    ```yaml
    - name: column_name
      data_tests:
        - dbt_expectations.expect_column_values_to_be_between:
            min_value: <n>
            config:
              where: "another_column != 'some_value'"
    ```

---

## Step 6 - Run the full test suite and review severity split

- [ ] Step complete

```bash
dbt test --select staging.streaming
```

Review the output:

- Which tests are `warn` vs `error`?
- Are there any `warn` tests you think should actually be `error`? Vice versa?
- Would you add any tests to `store_failures` to make ongoing debugging easier?

As a group, agree on a short list of rules:
- "This type of test is always `error`: ..."
- "This type of test is always `warn`: ..."

This is the conversation that a real data team has when setting up a CI pipeline.

---

!!! success "Done?"
    You've moved from writing tests to *configuring* them - choosing severity, scoping with `where`, storing failures for debuggability, and adding statistical guardrails with `dbt_expectations`. These are the skills that separate a test suite that blocks CI from one that just generates noise.
