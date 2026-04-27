# Group 2 - Checklist Level 3

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

Open `_news__models.yml` and `_podcasts__models.yml` and apply the following configuration:

1. Set `severity: warn` on the `accepted_values` test for `status` in `stg_news__articles` - new statuses may be added legitimately and shouldn't hard-fail CI.
2. Add a `where` filter to the `unique` test on `article_id` so it only evaluates `published` articles (drafts may intentionally appear multiple times while being edited).
3. Set `severity: warn` on the `relationships` test linking `author_id` → `stg_news__authors` - orphaned authors are worth flagging but shouldn't block a deploy.

??? tip "Hint: Test config syntax"
    Add a `config:` block nested inside any test to change its behaviour:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            values: [...]
            config:
              severity: warn

        - unique:
            config:
              where: "column_name = 'some_value'"

        - relationships:
            to: ref('model_name')
            field: column_name
            config:
              severity: warn
    ```

---

## Step 3 - Enable `store_failures` on a test

- [ ] Step complete

`store_failures: true` writes failing rows to a table in your target schema, making it easy to query and understand *which* rows caused the failure.

Enable it on the `not_null` test for `published_at` in `stg_news__articles`. Add a `limit` to cap the size of the failures table.

Run the test:

```bash
dbt test --select stg_news__articles
```

Then find and query the failures table in Snowflake. Does seeing the actual failing rows help you understand the issue faster than a simple pass/fail count?

??? tip "Hint: store_failures config"
    Add `store_failures` inside a `config:` block on the test:

    ```yaml
    - name: column_name
      data_tests:
        - not_null:
            config:
              store_failures: true
              limit: <n>
    ```

??? tip "Hint: Finding the failures table"
    After running, dbt prints the table name in the run output:

    ```
    Stored N failures in: <schema>.<test_name>
    ```

    The `limit` cap prevents very large failure tables from filling your schema.

---

## Step 4 - Add `dbt_expectations` tests to `stg_news__articles`

- [ ] Step complete

Add statistical guardrails to the articles model:

- The table should have at least 20 rows (catch a silent seed/source failure)
- `word_count` should be between 50 and 5000 (catch data entry errors - no article is 2 words or 50,000 words)
- `word_count` should be non-null for published articles only

??? tip "Hint: Row count and value bounds"
    Row count tests go at the model level; value tests go under a column:

    ```yaml
    - name: model_name
      data_tests:
        - dbt_expectations.expect_table_row_count_to_be_between:
            min_value: <n>
      columns:
        - name: column_name
          data_tests:
            - dbt_expectations.expect_column_values_to_be_between:
                min_value: <n>
                max_value: <n>
            - dbt_expectations.expect_column_values_to_not_be_null:
                row_condition: "status = 'published'"  # scope the test to rows where null is not acceptable
    ```

---

## Step 5 - Add `dbt_expectations` tests to `stg_podcasts__episodes`

- [ ] Step complete

Add guardrails to the episodes model:

- `duration_seconds` should be between 60 and 14400 (1 minute to 4 hours)
- The table should have at least 10 rows
- The distinct set of `show_id` values should be a subset of the shows that exist in `stg_podcasts__shows` - use `expect_column_values_to_be_in_set` with a hardcoded list, or think about which built-in test already covers this relationship

??? tip "Hint: Duration bounds"
    ```yaml
    - name: column_name
      data_tests:
        - dbt_expectations.expect_column_values_to_be_between:
            min_value: <n>
            max_value: <n>
    ```

    Think about what duration values would indicate a genuine data problem rather than just a statistical edge case.

??? tip "Hint: Relationship vs expectations"
    The `relationships` generic test already covers foreign key checks. `dbt_expectations` adds value for *statistical* bounds - ranges, null rates, row counts - not for referential integrity, where the built-in test is cleaner and faster.

---

## Step 6 - Add `dbt_expectations` tests to `content_performance`

- [ ] Step complete

Add mart-level guardrails:

- The mart should have at least 30 rows
- `platform` should only ever be `'news'` or `'podcasts'` - use `expect_column_distinct_values_to_equal_set` (this is stricter than `accepted_values`: it also fails if a *new* platform appears that isn't in the set)
- `published_at` should never be null - use `expect_column_values_to_not_be_null`

??? tip "Hint: Strict distinct value check"
    ```yaml
    - name: column_name
      data_tests:
        - dbt_expectations.expect_column_distinct_values_to_equal_set:
            value_set: ['val1', 'val2', ...]
    ```

    `expect_column_distinct_values_to_equal_set` is stricter than `accepted_values` - it fails if a value appears that isn't in your set, but *also* if a value in your set doesn't appear in the column at all. Contrast with `expect_column_distinct_values_to_be_in_set`, which only checks one direction.

---

## Step 7 - Run the full test suite and review severity split

- [ ] Step complete

```bash
dbt test --select staging.news staging.podcasts marts.content
```

Review the output and discuss as a group:

- Which tests block CI (`error`) vs flag for investigation (`warn`)?
- Where did you use `where` to scope a test - and was the scoping decision correct?
- Which `store_failures` tables would you keep permanently vs enable only for debugging?

---

!!! success "Done?"
    You've moved from writing tests to *configuring* them - choosing severity, scoping with `where`, storing failures for debuggability, and adding statistical guardrails with `dbt_expectations`. These are the skills that separate a test suite that blocks CI from one that just generates noise.
