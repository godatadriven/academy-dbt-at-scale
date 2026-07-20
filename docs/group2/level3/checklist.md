# Group 2 - Checklist Level 3

## Advanced Testing: Custom Generic Tests

Start on this checklist once you have completed [Level 2](../level2/checklist.md).

In this level you will:

- **Write custom generic tests** that encode business rules once and apply them everywhere

Read the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests) before starting.

---

## Step 1 - Understand when to write a custom generic test

- [ ] Step complete

The four built-in generic tests (`not_null`, `unique`, `accepted_values`, `relationships`) cover data quality at the column level. Custom generic tests let you encode any business rule as a reusable test.

Answer these questions before writing any code:

1. What business rules exist in your domain that the built-in tests cannot express?
2. If you wrote a singular test for one of those rules, could the same logic apply to a different model or column? If yes, a generic test is the right tool.
3. What arguments would a generic version of that test need to accept?

Read the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests) for the `{% test %}` macro structure.

---

## Step 2 - Write a `assert_category_has_group` generic test

- [ ] Step complete

In the content performance domain, every `category` value should map to a `category_group` in the seed. A category with no group is a data quality problem.

Write a generic test `assert_column_not_null_when_other_not_null.sql` in `tests/generic/`. The test should accept:

- `model`: the model being tested
- `column_name`: the column that must not be null
- `when_column`: the column whose non-null value triggers the check

The test should return rows where `column_name` is null but `when_column` is not null.

Apply it to `fct_content_performance` in `mediapulse_analytics`: assert that `category_group` is not null whenever `category` is not null.

Run the test and confirm it catches the case.

---

## Step 3 - Write a `assert_value_in_range` generic test

- [ ] Step complete

Write a generic test `assert_value_in_range.sql` in `tests/generic/`. The test should accept:

- `model`: the model being tested
- `column_name`: the column to check
- `min_value`: minimum allowed value (inclusive)
- `max_value`: maximum allowed value (inclusive)

It should return rows where the column falls outside the range.

Apply it to `content_length_units` in `fct_content_performance` with a minimum of 1 and a sensible maximum based on your knowledge of the data. What maximum would you choose, and why?

---

## Step 4 - Refactor an existing singular test into a generic test

- [ ] Step complete

Look at the existing singular test approach in Level 1 (`dbt test` assertions). Pick one business rule that could be generalised and rewrite it as a generic test.

After creating the generic test, apply it to at least two different models or columns to prove the reusability.

---

## Step 5 - Review test strategy across the content domain

- [ ] Step complete

```bash
dbt test --select staging.news staging.podcasts
```

With your group, review the output:

- Which tests are `error` severity vs `warn`?
- Are there tests that would benefit from `where` clauses to scope them correctly?
- Which tests would you add `store_failures: true` to permanently?

Draft a short test contract for `stg_news__articles`: what does the test suite guarantee to downstream consumers?

Read the [data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for configuration syntax if needed.

---

## Step 6 - CAPSTONE: design and build `fct_content_engagement`

- [ ] Step complete

The content domain is missing its engagement fact table. `fct_content_performance` (in `mediapulse_analytics`) describes *what* content exists, but nothing in the project yet measures *how much it was read or listened to*. That is your job.

Create `models/marts/content/fct_content_engagement.sql` in `mediapulse_platform`.

Decide the grain yourself, then check it against these questions:

1. What does one row represent - one page view? One listen? Or an aggregate, like one content item per day?
2. `stg_news__page_views` (the incremental model you built in Level 1) is already at view-event grain. What aggregation, if any, does it need to reach the grain you chose?
3. `int_episode_listen_completion` already aggregates podcast listens to one row per episode - across all time, with no date. Can you combine it with a daily-grain news metric without misrepresenting either one? What grain compromise or caveat would you document?

A reasonable core scope:

- One row per `content_id` (article) per `engagement_date`
- Columns: `content_id`, `platform`, `engagement_date`, `engagement_count` (views that day), `unique_users`
- Built from `stg_news__page_views` joined to `stg_news__articles` for context

??? tip "Hint: getting started"
    Group and count `stg_news__page_views` by `article_id` and the date part of `viewed_at`. That alone gives you a working, if news-only, `fct_content_engagement`. Get that running and tested before attempting the podcast side.

??? tip "Stretch: bring podcasts into the same fact"
    PodcastHub has no staging model for listens yet - `int_episode_listen_completion` reads straight from `source('podcasts', 'listens')`, bypassing staging entirely (which is itself a violation Group 3's dbt-project-evaluator audit would flag).

    To fold podcasts into `fct_content_engagement` properly:

    1. Build `stg_podcasts__listens.sql`, mirroring the pattern you used for `stg_news__page_views`.
    2. Aggregate it to daily grain per episode, the same way you aggregated page views per article.
    3. `union all` the two daily-grain results together, normalising both to the same column names (`content_id`, `platform`, `engagement_date`, `engagement_count`, `unique_users`) - the same pattern that fixes the bug in `fct_content_performance`.

Document the model in a new `_content__models.yml` alongside it: a description, and `not_null`/`unique` tests on the grain you chose. Run and test it:

```bash
dbt build --select fct_content_engagement
```

---

!!! success "Done?"
    You have written reusable custom generic tests that encode your domain's business rules in one place and apply them everywhere, and designed the content domain's missing fact table from event-grain data. Combined with the incremental models and macros from Levels 1 and 2, you have a production-ready analytics engineering foundation.
