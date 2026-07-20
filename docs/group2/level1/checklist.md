# Group 2 - Checklist Level 1

## Modeling Best Practices and Incremental Models

Start here. The first steps review the existing project for structural best-practice violations, then move into building an incremental model for a high-volume event table.

In this level you will:

- **Audit** existing staging models for best-practice violations
- **Fix** staging bugs and improve the models
- **Build** an incremental staging model for the news page views event stream

Work through the steps in order. Expand a hint only after you've had a genuine attempt.

---

## Step 1 - Review the project structure

- [ ] Step complete

Before writing any code, do a manual audit. Open each staging model in `mediapulse_platform/models/staging/` and answer these questions for each:

- Does it select from `{{ source(...) }}` or from raw SQL table references?
- Does it have a corresponding YAML file with tests?
- Are primary keys tested with both `not_null` and `unique`?
- Are there any columns that should be renamed or normalised but are not?

Make a note of the gaps. You will fix them in the next steps.

??? tip "Hint: what to look for"
    Common violations in real projects:

    - Models that select `*` without explicitly named columns (no control over what comes through)
    - Missing tests on primary keys (silent duplicates can propagate downstream)
    - String columns that are not normalised (mixed casing causes silent join misses)
    - Monetary values stored in cents without conversion
    - Missing descriptions on models and columns

---

## Step 2 - Audit `stg_news__articles.sql`

- [ ] Step complete

Open `stg_news__articles.sql` and compare it to the raw `news.articles` table. Run:

```sql
select
    article_id,
    count(*) as row_count
from news.articles
group by article_id
having count(*) > 1
```

Are there duplicate `article_id` values? Does the staging model handle them? What happens to the `fct_content_performance` mart if duplicates flow through?

---

## Step 3 - Fix `stg_news__articles.sql`

- [ ] Step complete

Fix the deduplication issue: keep only the most recent row per `article_id` (highest `updated_at`).

After fixing, run the tests:

```bash
dbt test --select stg_news__articles
```

??? tip "Hint"
    A `row_number()` window function partitioned by `article_id` and ordered by `updated_at desc` assigns each row a rank. Filter to `row_num = 1` to keep only the most recent.

---

## Step 4 - Audit `stg_podcasts__episodes.sql`

- [ ] Step complete

Open `stg_podcasts__episodes.sql` and try to run it:

```bash
dbt run --select stg_podcasts__episodes
```

Read the error message. What column does the model reference that does not exist in the raw table? Fix it.

Then query the staged model and try ordering by `season_episode`. Does the ordering look right? Is there a second issue?

??? tip "Hint: the season_episode ordering problem"
    The `season_episode` column stores values like `1-3`, `2-10`, `3-2`. Because it is a string, `'2-10'` sorts before `'2-9'` (character comparison). Any downstream model ordering by this column silently returns episodes in the wrong order once season episode counts exceed 9.

    Fix both the column name bug and the ordering problem by splitting `season_episode` into separate integer columns.

---

## Step 5 - Fill test gaps in existing YAML

- [ ] Step complete

Look at `_news__models.yml` and `_podcasts__models.yml`. Using the audit from Step 1, add the missing tests. At a minimum:

- `not_null` and `unique` on every primary key
- `accepted_values` on `status` in `stg_news__articles` (expected values: `draft`, `published`, `archived`)
- A `relationships` test linking `stg_news__articles.author_id` to `stg_news__authors.author_id`

Read the [dbt data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for the syntax.

Run the tests and understand any failures before deciding how to handle them:

```bash
dbt test --select stg_news__articles stg_news__authors stg_podcasts__episodes stg_podcasts__shows
```

---

## Step 6 - Understand incremental models

- [ ] Step complete

Before building anything, read the [incremental models documentation](https://docs.getdbt.com/docs/build/incremental-models) and answer these questions for `news.page_views`:

1. What is the grain of the `page_views` table? (one row per what?)
2. Do existing rows ever change after they are first written, or are new events always new rows?
3. Which column would you use as the high-watermark filter on subsequent runs?
4. Given your answers, which incremental strategy fits best: `append`, `merge`, or `insert_overwrite`?

Discuss with your group before moving on. The answers drive your config choices.

??? tip "Hint: how the strategies differ"
    - `append`: inserts new rows only. Fastest and simplest. Correct when source rows never change after they are written.
    - `merge`: upserts on a `unique_key`. Handles late-arriving or corrected rows. Slightly slower.
    - `insert_overwrite`: deletes and rewrites a whole partition. Best for very large tables with a clear partition boundary (e.g. by month).

    Page view events are immutable once written. A user cannot retroactively un-view an article. That points to one strategy.

---

## Step 7 - Build `stg_news__page_views.sql` as an incremental model

- [ ] Step complete

Create `models/staging/news/stg_news__page_views.sql`.

The source table `news.page_views` records every page view event. It is high volume and append-only. Build this as an incremental staging model using the strategy you chose in Step 6.

The model should:

- Reference `{{ source('news', 'page_views') }}`
- Rename columns to be consistent with the rest of the staging layer
- Cast `viewed_at` to a proper timestamp type
- Include an `{% if is_incremental() %}` filter so subsequent runs only process new rows

Read the [incremental models documentation](https://docs.getdbt.com/docs/build/incremental-models) for the `is_incremental()` macro and the `config()` block syntax.

Run it twice and compare the row counts:

```bash
dbt run --select stg_news__page_views
dbt run --select stg_news__page_views   -- second run: fewer rows processed
```

??? tip "Hint: the is_incremental filter pattern"
    Inside the `{% if is_incremental() %}` block, filter the source to rows where the watermark column is greater than the maximum value already in the current table. Use `{{ this }}` to reference the existing table:

    ```sql
    where viewed_at > (select coalesce(max(viewed_at), '1900-01-01') from {{ this }})
    ```

    On the first run, `{{ this }}` does not exist, so the `{% if is_incremental() %}` block is skipped and all rows load.

---

## Step 8 - Add the page views source definition

- [ ] Step complete

Add `page_views` to `_news__sources.yml`. Add at minimum a `not_null` test on `view_id`.

Read the [dbt sources documentation](https://docs.getdbt.com/docs/build/sources) for the syntax if needed.

---

## Step 9 - Document `stg_news__page_views` in YAML

- [ ] Step complete

Add `stg_news__page_views` to `_news__models.yml`. Include:

- A model description
- `not_null` and `unique` tests on the primary key
- A `not_null` test on `viewed_at`
- A `relationships` test linking `view_id` to `article_id` in `stg_news__articles`

---

## Step 10 - BONUS: Run dbt build across news staging

- [ ] Step complete

```bash
dbt build --select staging.news
```

Fix any failures, then open the lineage graph and confirm `stg_news__page_views` appears with green source nodes from `news`.

---

!!! success "Done?"
    You have audited the existing models, fixed two staging bugs, filled test gaps, and built an incremental model for a high-volume event stream. You now understand why and when incremental matters.

    Head to [Level 2](../level2/checklist.md) to add Jinja and macros!
