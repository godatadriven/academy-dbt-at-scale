# Group 1 — Checklist

Work through the steps in order. Expand a hint only after you've had a genuine attempt — the struggle is where the learning happens.

---

## Step 1 — Explore the raw streaming tables

Before writing any dbt code, understand what you're working with. Query the raw tables and note:

- How many rows are in each table?
- What does a typical row look like?
- Are there any obvious quality issues (nulls, unexpected values, duplicate IDs)?

```sql
select * from raw_streaming.watch_events limit 20;
select * from raw_streaming.subscriptions limit 20;
select * from raw_streaming.content_catalog limit 20;
```

??? tip "Hint: What to look for"
    Pay attention to:

    - `monthly_fee_cents` in `subscriptions` — is this in the right unit for reporting?
    - `status` in `subscriptions` — what values exist? Are they consistent?
    - `device_type` in `watch_events` — any inconsistent casing?

    You'll use these observations to write accepted_values tests and decide where to apply your macros.

---

## Step 2 — Define sources in YAML

Create the file `models/staging/streaming/_streaming__sources.yml`. Define a source named `streaming` with all three tables.

??? tip "Hint: Source YAML structure"
    ```yaml
    version: 2

    sources:
      - name: streaming
        database: "{{ env_var('DBT_DATABASE') }}"
        schema: raw_streaming
        tables:
          - name: watch_events
          - name: subscriptions
          - name: content_catalog
    ```

    The `name` under `sources` is what you use in `{{ source('streaming', 'watch_events') }}` calls.

---

## Step 3 — Add source freshness config

Add a `loaded_at_field` and `freshness` block to at least one table (start with `watch_events`).

??? tip "Hint: Freshness config"
    ```yaml
    tables:
      - name: watch_events
        loaded_at_field: watched_at
        freshness:
          warn_after: {count: 6, period: hour}
          error_after: {count: 24, period: hour}
    ```

    Test it with:

    ```bash
    dbt source freshness --select source:streaming.watch_events
    ```

    dbt compares `max(watched_at)` against the current timestamp and raises a warning or error if data is older than the threshold.

---

## Step 4 — Add generic tests to sources

Add `not_null` and `unique` tests to the primary key of each table. Also add at least one `accepted_values` test.

??? tip "Hint: Tests on source columns"
    ```yaml
    tables:
      - name: subscriptions
        columns:
          - name: subscription_id
            tests:
              - not_null
              - unique
          - name: status
            tests:
              - accepted_values:
                  values: ['active', 'cancelled', 'paused', 'trialing']
          - name: plan_type
            tests:
              - accepted_values:
                  values: ['basic', 'standard', 'premium']
    ```

    Run source tests:

    ```bash
    dbt test --select source:streaming
    ```

---

## Step 5 — Build `stg_streaming__content_catalog.sql`

Create `models/staging/streaming/stg_streaming__content_catalog.sql`. This is the simplest of the three models — no surrogate key needed, just renaming and casting.

Goals:

- Rename columns to be clear and consistent
- Cast `release_date` to `date` if it's stored as a string
- Lowercase `genre` and `content_type` for consistency

??? tip "Hint: Starter template"
    ```sql
    with source as (
        select * from {{ source('streaming', 'content_catalog') }}
    ),

    renamed as (
        select
            content_id,
            title                               as content_title,
            lower(trim(genre))                  as genre,
            lower(trim(content_type))           as content_type,
            cast(release_date as date)          as release_date,
            runtime_minutes
        from source
    )

    select * from renamed
    ```

    The `lower(trim(...))` pattern normalises values you'll later use in `accepted_values` tests.

---

## Step 6 — Build `stg_streaming__subscriptions.sql`

Create `models/staging/streaming/stg_streaming__subscriptions.sql`.

Goals:

- Convert `monthly_fee_cents` to dollars (you'll write a macro for this in Step 8 — use a manual divide for now)
- Normalise `status` to lowercase
- Cast date columns to `timestamp`

??? tip "Hint: Handling cents"
    ```sql
    monthly_fee_cents / 100.0 as monthly_fee_dollars
    ```

    You'll replace this inline calculation with your `cents_to_dollars` macro in Step 9 after you've written it.

---

## Step 7 — Build `stg_streaming__watch_events.sql`

Create `models/staging/streaming/stg_streaming__watch_events.sql`.

This is the highest-volume table — fact-style, one row per viewing event. You need a surrogate key because `event_id` from the source may not be globally unique across data loads.

??? tip "Hint: Surrogate key with dbt_utils"
    If `dbt_utils` is in `packages.yml`:

    ```sql
    {{
        dbt_utils.generate_surrogate_key(['event_id', 'user_id', 'watched_at'])
    }}   as watch_event_sk
    ```

    If you'd rather write your own (Step 8 covers this), use a placeholder for now and come back:

    ```sql
    -- placeholder: replace with macro after Step 8
    cast(event_id as varchar) as watch_event_sk
    ```

---

## Step 8 — Write a `clean_string` macro

Create `macros/clean_string.sql`. The macro should accept a column name and return an expression that trims whitespace, converts to lowercase, and coalesces nulls to an empty string.

??? tip "Hint: Macro skeleton"
    ```sql
    {% macro clean_string(column_name) %}
        coalesce(lower(trim({{ column_name }})), '')
    {% endmacro %}
    ```

    Note: macros receive expressions, so callers pass the column name as a string argument. Call it like:

    ```sql
    {{ clean_string('device_type') }} as device_type
    ```

---

## Step 9 — Write a `cents_to_dollars` macro

Create `macros/cents_to_dollars.sql`. The macro accepts a column name and returns the division expression.

??? tip "Hint: Macro"
    ```sql
    {% macro cents_to_dollars(column_name) %}
        {{ column_name }} / 100.0
    {% endmacro %}
    ```

    Now go back to `stg_streaming__subscriptions.sql` and replace the inline division:

    ```sql
    {{ cents_to_dollars('monthly_fee_cents') }} as monthly_fee_dollars
    ```

    Run the model to confirm it still compiles and produces correct values:

    ```bash
    dbt run --select stg_streaming__subscriptions
    dbt show --select stg_streaming__subscriptions --limit 5
    ```

---

## Step 10 — Apply `clean_string` in `stg_streaming__watch_events.sql`

Update your watch events staging model to use `clean_string` on `device_type`.

??? tip "Hint: In context"
    ```sql
    {{ clean_string('device_type') }} as device_type,
    ```

    Then test that your `accepted_values` test on `device_type` still passes — the normalisation should reduce the value set to a predictable list.

---

## Step 11 — Create a staging models YAML

Create `models/staging/streaming/_streaming__models.yml`. Document all three staging models with at minimum:

- A model-level description
- `not_null` + `unique` tests on the primary key column
- `not_null` tests on key foreign keys and timestamp columns

??? tip "Hint: YAML structure for a model"
    ```yaml
    version: 2

    models:
      - name: stg_streaming__content_catalog
        description: >
          One row per piece of content in the StreamVault catalogue.
          Cleaned and renamed from raw_streaming.content_catalog.
        columns:
          - name: content_id
            description: Primary key — unique identifier for a content item.
            tests:
              - not_null
              - unique
          - name: content_title
            tests:
              - not_null
          - name: genre
            tests:
              - not_null
              - accepted_values:
                  values: ['drama', 'comedy', 'sport', 'documentary', 'news', 'kids']
    ```

---

## Step 12 — Run the full test suite

```bash
dbt test --select staging.streaming
```

Fix any failures. A test failure is information — read the error message, query the failing rows, understand why.

??? tip "Hint: Investigating a test failure"
    To see failing rows for a `not_null` test on `content_id`:

    ```sql
    select *
    from {{ ref('stg_streaming__content_catalog') }}
    where content_id is null
    ```

    For an `accepted_values` failure, see which unexpected values exist:

    ```sql
    select distinct genre
    from {{ ref('stg_streaming__content_catalog') }}
    order by 1
    ```

    Decide: fix the source assertion (update the accepted list) or fix the data transformation.

---

## Step 13 — BONUS: `dbt build` and check lineage

Run:

```bash
dbt build --select staging.streaming
```

This runs models + tests in dependency order in a single command. Then open the dbt docs or the DAG viewer in dbt Cloud to confirm your three models appear correctly sourced from `raw_streaming`.

??? tip "Hint: Generating docs locally"
    ```bash
    dbt docs generate
    dbt docs serve
    ```

    Open `http://localhost:8080` and navigate to the DAG. You should see `raw_streaming` → `stg_streaming__*` with green source nodes.

---

!!! success "Done?"
    If all tests pass and the DAG looks right, you've successfully wired a new data domain into the MediaPulse project. Share your findings with the other groups — Group 3 will build on the ads domain using the same patterns you've just practised.
