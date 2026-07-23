# Group 1 - Checklist Level 1

## dbt Modeling Refresh and Bug Fixing

Start here. The first steps cover the fundamentals so everyone in the group is working from the same base, then move into finding and fixing real bugs.

In this level you will:

- **Review** how sources, tests, and staging models fit together
- **Fix bugs** in existing staging models by reading error output
- **Build** the streaming staging layer from scratch
- **Add tests** and source freshness to your new models

Work through the steps in order. Expand a hint only after you've had a genuine attempt. The struggle is where the learning happens.

---

## Step 1 - Orient yourself: run dbt build

- [ ] Step complete

Open `mediapulse_platform` in dbt Cloud and run:

```bash
dbt build
```

Read the output carefully. How many models ran? How many failed? What do the error messages say?

Write down the names of any failing models and the exact error text. You will come back to these.

??? tip "Hint: reading dbt error output"
    The key line in a dbt error is the one that says `Compilation Error` or `Database Error`. Everything below that tells you which model broke and why. The model name appears in the path, e.g. `model.mediapulse_platform.stg_podcasts__episodes`.

---

## Step 2 - Fix `stg_podcasts__episodes.sql`

- [ ] Step complete

Open `models/staging/podcasts/stg_podcasts__episodes.sql` and compare it to the raw source table:

```sql
select * from podcasts.episodes limit 10
```

Find the column name that the model is referencing incorrectly. Fix it, then run:

```bash
dbt run --select stg_podcasts__episodes
```

Once the model runs, query it and try ordering by the column named `episode_season`. What do you notice about the ordering?

??? tip "Hint: two bugs in one model"
    The first bug is a column name mismatch: the raw table uses a different name than what the model selects. Fix that first.

    The second issue is in how `episode_season` is constructed. It stores season and episode as a combined string like `1-3`, where the episode number comes first. This means ordering by the string produces wrong results (all episode 1s together, then all episode 2s). A downstream model ordering chronologically would silently return episodes in the wrong sequence.

    Fix both: 
    - correct the column name that has changed
    - split `episode_season` into two separate integer columns called `season` and `episode_number`.

---

## Step 3 - Audit `stg_news__articles.sql`

- [ ] Step complete

Open `models/staging/news/stg_news__articles.sql` and read it carefully.

Then query the raw source to understand the data:

```sql
select
    *
from news.articles
order by article_id
```

What does this table capture? Does it capture articles or article upload events? 

??? tip "Hint: the deduplication problem"
    The raw `articles` table contains events, capturing the status of the article at that time. 
    This is not an issue, but should be corrected for - should the table really be called `articles` or `article_events`?
    
    At some point in the project, the articles need to be deduplicated so that they can be used independently of the status update information. This can be done in an intermediate model `int_dedupe_articles.sql`. 

    The fix: 
    - rename the staging model to `stg_news__article_events`
    - make an intermediate model to keep only the most recent row per `article_id` (the one with the highest `updated_at`).

---

## Step 4 - Add tests to the intermediate model

- [ ] Step complete

Now that you have an intermediate model that deduplicates the `article_id` field, it's time to test whether this primary key is valid. 

??? tip "Hint: Testing the primary key"
    - Create a new yaml file for the intermediate model created in step 3.
    - Add the unique and not_null tests to the `article_id` column.

---

## Step 5 - Define sources for the streaming domain

- [ ] Step complete

Create `models/staging/streaming/_streaming__sources.yml`. Define a source named `streaming` with all three tables: `watch_events`, `subscriptions`, and `content_catalog`.

Read the [dbt sources documentation](https://docs.getdbt.com/docs/build/sources) before you write the YAML.

Things to decide:

- What `name` do you give each table? You can use a more readable alias than the raw table name.
- Which primary key column do you test on each table?
- Does the database and schema match where the raw data lives?

After creating the file, run:

```bash
dbt test --select source:streaming
```

??? tip "Hint: getting started with source freshness"
    The sources documentation covers freshness configuration under the `loaded_at_field` and `freshness` keys. Add these to `watch_events` once your basic source definition is working. Use the `watched_at` column as the freshness marker. Run freshness checks with:

    ```bash
    dbt source freshness --select source:streaming
    ```

---

## Step 6 - Build `stg_streaming__content_catalog.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__content_catalog.sql`.

Use the `Generate model` button in the dbt Cloud IDE to scaffold it from your source definition, then make the following improvements:

- Rename columns to be clear and consistent with the rest of the project
- Normalise `genre` and `content_type`: check for casing inconsistencies

```sql
select distinct genre from {{ source('streaming', 'content_catalog') }}
```

What values do you see? Are they consistent?

??? tip "Hint: normalising string columns"
    `lower(trim(column_name))` removes leading and trailing whitespace and converts to lowercase. This is the standard pattern for normalising string columns before tests or joins.

---

## Step 7 - Build `stg_streaming__subscriptions.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__subscriptions.sql`.

Goals:

- Convert `monthly_fee_cents` to dollars
- Normalise the `status` column
- Create `started_at` and `ended_at` timestamps from the separate date and time columns in the raw table

??? tip "Hint: combining date and time columns into a timestamp"
    Snowflake accepts string concatenation to build a timestamp:

    ```sql
    cast(date_column || ' ' || time_column as timestamp) as started_at
    ```

---

## Step 8 - Build `stg_streaming__watch_events.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__watch_events.sql`.

This is the highest-volume table: one row per viewing event. Note that the raw `event_id` values are reused when the source system re-emits the event stream. This means `event_id` is not unique in the raw data.

You will need to generate a surrogate key from a combination of columns that together identifies a unique event. Use the `dbt_utils.generate_surrogate_key()` macro from the `dbt_utils` package (already installed).

??? tip "Hint: which columns to use for the surrogate key"
    Think about which combination of columns would make a row unique: user, content item, the time the event was recorded. Use those as inputs to `generate_surrogate_key`.

---

## Step 9 - Create a staging models YAML

- [ ] Step complete

Create `models/staging/streaming/_streaming__models.yml`. Document all three staging models with:

- A model-level description
- `not_null` and `unique` tests on the primary key of each model
- `not_null` tests on key foreign keys and timestamp columns

Read the [dbt data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for the test syntax.

??? tip "Hint: using codegen to scaffold the YAML"
    The `dbt-codegen` package can generate the column list from your compiled SQL so you don't have to write it by hand. If it is already in `packages.yml`, compile the `codegen.generate_model_yaml` macro for each model name and paste the output into your YAML file. Then add descriptions and tests.

---

## Step 10 - Run the full test suite

- [ ] Step complete

```bash
dbt test --select source:streaming+
```

Fix any failures. Read the error message before changing anything. Which rows are failing? Why?

---

!!! success "Done?"
    You've diagnosed and fixed two production bugs, built and tested a complete streaming staging layer, and added source freshness monitoring. That is a solid base.

    Head to [Level 2](../level2/checklist.md) to add seeds and snapshots!
