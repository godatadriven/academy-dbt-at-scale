# Group 1 - Checklist Level 3

## Next Level Testing: Configurations and Custom Generic Tests

Start on this checklist once you have completed [Level 2](../level2/checklist.md).

In this level you will:

- **Configure tests** with `severity`, `where`, and `store_failures`
- **Write custom generic tests** that are reusable across any model or column

Read the [dbt data tests documentation](https://docs.getdbt.com/docs/build/data-tests) and the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests) before starting.

---

## Step 1 - Audit your current test suite

- [ ] Step complete

Run the full test suite for the streaming staging layer:

```bash
dbt test --select staging.streaming
```

Then answer:

1. Which tests currently fail? Should a failure block CI or just flag for investigation?
2. Are there tests that apply to all rows but should only apply to a subset? (For example, a price check that should skip rows where price is legitimately zero.)
3. Which failing tests would be hardest to debug from a row count alone? Those are candidates for `store_failures`.

Make a list of the configuration changes you want to make before moving on.

---

## Step 2 - Add `severity` to appropriate tests

- [ ] Step complete

Open `_streaming__models.yml` and apply severity settings to the tests you identified:

- Set `severity: warn` on tests where a failure is worth investigating but should not block CI (for example, `accepted_values` tests on categories that might legitimately expand)
- Confirm that primary key tests (`not_null` and `unique` on the surrogate key) are set to `severity: error` (the default)

Read the [data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for the `config:` block syntax.

---

## Step 3 - Add `where` filters to scoped tests

- [ ] Step complete

Add `where` conditions to tests that should not evaluate all rows. For example:

- The `unique` test on `event_id` in `stg_streaming__watch_events` should exclude rows where the source system is known to re-emit duplicate IDs

Find the right filter by querying the duplicate rows:

```sql
select
    event_id,
    count(*) as cnt
from {{ ref('stg_streaming__watch_events') }}
group by event_id
having count(*) > 1
```

What distinguishes the duplicate rows from the unique ones? That condition is your `where` filter.

---

## Step 4 - Enable `store_failures` on revenue-sensitive tests

- [ ] Step complete

Enable `store_failures: true` on the tests most likely to fail in production: the `not_null` test on `watch_duration_seconds` and the `unique` test on the surrogate key.

Run the tests, then find the failures table in Snowflake. Does seeing the actual failing rows help you understand the issue faster than a row count alone?

Read the [data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for how to configure `store_failures` and `limit` at the test level.

---

## Step 5 - Write a custom generic test: `assert_not_negative`

- [ ] Step complete

Create `tests/generic/assert_not_negative.sql` in `mediapulse_platform`.

A generic test is a Jinja macro that accepts a model and a column name (and any additional arguments), and returns SQL that returns rows when the test fails.

Read the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests) for the `{% test %}` macro syntax.

The test should fail (return rows) for any row where the specified column is negative.

After creating the test, apply it in `_streaming__models.yml` to:

- `watch_duration_seconds` in `stg_streaming__watch_events`
- `monthly_fee_dollars` in `stg_streaming__subscriptions`

Run:

```bash
dbt test --select stg_streaming__watch_events stg_streaming__subscriptions
```

---

## Step 6 - Write a custom generic test: `assert_column_is_one_of`

- [ ] Step complete

Create `tests/generic/assert_column_is_one_of.sql`. This test should accept:

- `model`: the model being tested (automatically passed by dbt)
- `column_name`: the column to check (automatically passed by dbt)
- `allowed_values`: a list of acceptable values

It should fail for any row where the column value is not in the allowed list.

Apply it to `device_type` in `stg_streaming__watch_events` with the known allowed values. Run the test and compare its behaviour to the built-in `accepted_values` test. When would you use your custom version over the built-in one?

---

## Step 7 - Run the full suite and review

- [ ] Step complete

```bash
dbt test --select staging.streaming
```

Review the output with your group:

- Which tests are `warn` vs `error`? Does the split feel right?
- Are there any tests that would be more useful with `store_failures` enabled permanently?
- Draft one sentence that describes the testing contract for `stg_streaming__watch_events`: what guarantees does the test suite make to downstream consumers?

---

## Step 8 - CAPSTONE: design and build `fct_streaming_engagement`

- [ ] Step complete

The streaming domain has a fully tested staging layer, a seed, and a snapshot - but no fact table. Every other domain in MediaPulse ends with a governed fact model that downstream consumers can build on. Streaming's is still missing: `fct_streaming_engagement`.

Create `models/marts/streaming/fct_streaming_engagement.sql` in `mediapulse_platform`.

Grain: one row per watch event (the same grain as `stg_streaming__watch_events`).

A reasonable core scope, joining the three staging models you already built:

- `user_id`, `content_id`, `watched_at`, `watch_duration_seconds`, `device_category` from `stg_streaming__watch_events`
- `plan_type` from `stg_streaming__subscriptions`, joined on `user_id`
- `genre` and `content_type` from `stg_streaming__content_catalog`, joined on `content_id`

??? tip "Hint: which key to join subscriptions on"
    `stg_streaming__watch_events` doesn't carry a `subscription_id`. Join to `stg_streaming__subscriptions` on `user_id` instead. What happens if a user has more than one subscription record over time? Decide how you want to handle that before writing the join - it's the same class of problem your snapshot exists to solve.

??? tip "Stretch: resolve plan_type as of the watch event, not today"
    Joining directly to `stg_streaming__subscriptions` gives you the user's *current* plan, not the plan they were on when they watched. You built `snap_streaming__subscriptions` in Level 2 specifically to answer "what was true at a point in time."

    Join to the snapshot instead, matching `watched_at` between `dbt_valid_from` and `coalesce(dbt_valid_to, current_timestamp())`. This gets you the plan_type that was actually active at watch time - a much more defensible number for any churn or plan-tier analysis downstream.

Document the model in a new `_streaming__marts.yml` alongside it: a description, and `not_null`/`unique` tests on your grain key. Run and test it:

```bash
dbt build --select fct_streaming_engagement
```

---

!!! success "Done?"
    You have configured an existing test suite with severity, scoping, and failure storage, written two custom generic tests that are reusable across the whole project, and designed the streaming domain's fact table from your own staging layer. These skills turn a basic test suite into a production-ready one - and a documented staging layer into a usable analytics product.
