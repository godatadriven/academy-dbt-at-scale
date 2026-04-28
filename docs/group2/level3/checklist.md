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
            arguments:
              values: [...]
            config:
              severity: warn

        - unique:
            config:
              where: "column_name = 'some_value'"

        - relationships:
            arguments:
              to: ref('model_name')
              field: column_name
            config:
              severity: warn
    ```

---

## Step 3 - Enable `store_failures` on a test

- [ ] Step complete

`store_failures: true` writes failing rows to a table in your target schema, making it easy to query and understand *which* rows caused the failure.

Add a `unique` test to the `article_id` in the source `news.articles` - recall that this column is not unique *in the source* since articles can be republished.

Run the test:

```bash
dbt test --select source:news
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
---

## Step 4 - Add `dbt_expectations` tests to `stg_news__articles`

- [ ] Step complete

Add statistical guardrails to the articles model:

- The table should have at least 20 rows (catch a silent seed/source failure)
- `word_count` should be between 50 and 5000 (catch data entry errors - no article is 2 words or 50,000 words)

??? tip "Hint: Row count and value bounds"
    Row count tests go at the model level; value tests go under a column:

    ```yaml
    - name: model_name
      data_tests:
        - dbt_expectations.expect_table_row_count_to_be_between:
            arguments:
              min_value: <n>
      columns:
        - name: column_name
          data_tests:
            - dbt_expectations.expect_column_values_to_be_between:
                arguments:
                  min_value: <n>
                  max_value: <n>  # scope the test to rows where null is not acceptable
    ```

---

## Step 5 - Add `elementary` tests to `context_performance`

- [ ] Step complete

Check out the [elementary package.]().

Install the package into your project.

Add the [anomaly test](https://docs.elementary-data.com/data-tests/anomaly-detection-tests/column-anomalies#column_anomalies) to the duraction column to check whether the number of 

Add the [anomaly test](https://docs.elementary-data.com/data-tests/anomaly-detection-tests/column-anomalies#column_anomalies) to the duration column to check whether the number of 
seconds in an episode falls outside the expected range based on historical averages.

!!! note "Before running your tests, make sure Elementary's internal tables exist in your schema"

    ```bash
    dbt run --select elementary
    ```
    You only need to do this once per environment.
    What do you see in your output?

When would this test fail?

---

## Step 6 - Add a singular test

Add a singular test to ensure that if there is a `category` in the `content_performance` mart there is always a `category_group`.

??? tip "Hint: What is a custom singular test??"
    Singular tests are plain `.sql` files that return rows when they **fail**. 
    
    They live in the `tests/` directory. It should be called `assert_<test_functionality>.sql`, where you finish the name describing what the test is doing.

When you have your test save run 
```bash
dbt test --select `content_peformance`
```

Does your new test pass?

??? lab "Extension: convert this test to a generic test"
    Generic tests live in the `tests/generic/` folder and are reusable across any model and column.
    
    Can you refactor your singular test into a generic one that accepts the model and a list of expected values as arguments?

    1. Create a folder called `generic/` in the `tests/` directory
    2. Move your current test into the new folder `generic/`

    ```sql
    {% test assert_two_columns_are_equal(model, column_name, other_column_name) %}
    
    select
      {{ column_name }}
    from {{ model }}
    where {{ column_name }} = {{ other_column_name }}

    {% endtest %}
    ```

Once you have written your generic, how would you apply it in a `.yml` file?

??? question "How to apply a generic test in a yaml file?"
    Given a generic test, you can apply it in a `.yml` file like this:

    ```yaml
    - name: model_name
      columns:
        - name: column_name
          data_tests:
            - assert_two_columns_are_equal:
                other_column_name: other_column
    ```

    The arguments (`model`, `column_name`) are always the model and column the test is defined under. Any additional arguments become named parameters beneath the test name.

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

## Stretch your test suite! What else would you cover?

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