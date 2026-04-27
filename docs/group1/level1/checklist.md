# Group 1 - Checklist Level 1

## dbt Fundamentals

Start here to practice and apply the dbt fundamental skills:

- **Sources** and source freshness
- **Testing** primary keys with built-in tests
- **Staging models**
- **Documentation**
- **Making use of packages**: `codegen` 

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Explore the raw streaming tables

- [ ] Step complete

Before writing any dbt code, understand what you're working with. Query the raw tables and note:

- How many rows are in each table?
- What does a typical row look like?
- Are there any obvious quality issues (nulls, unexpected values, duplicate IDs)?

```sql
select * from streaming.watch_events
```

```sql
select * from streaming.subscriptions
```

```sql
select * from streaming.content_catalog
```

??? tip "Hint: What to look for"
    Pay attention to:

    - `monthly_fee_cents` in `subscriptions` - is this in the right unit for reporting?
    - `status` in `subscriptions` - what values exist? Are they consistent?
    - `genre` or `content_type` in `content_catalog` - any inconsistent casing?

    You'll use these observations to write tests and decide what transformations are needed at the staging layer.

---

## Step 2 - Define sources in YAML

- [ ] Step complete

Create the file `models/staging/streaming/_streaming__sources.yml`. Define a source named `streaming` with all three tables.

!!! note "Rename the tables with more human readable names"

??? tip "Hint: Source YAML structure"
    ```yaml
    version: 2

    sources:
      - name: source_name # you choose this
        database: can be dynamically set using "{{ env_var('DBT_DATABASE') }}"
        schema: name_of_schema
        tables:
          - name: table_name # you choose this
            identifier: table_name_as_in_warehouse
          - name: table_name_2 # you choose this
            identifier: table_name_2_as_in_warehouse
    ```

    Then you'll refer to this using `{{ source('source_name', 'table_name') }}` calls.

---

## Step 3 - Add generic tests to sources

- [ ] Step complete

Add the following tests to the primary keys of each table:
- `not_null`
- `unique` 

You will need to add a new key called `columns:` to configure the name of the primary key column. Then you'll need to add the key `data_tests:`.

??? tip "Hint: Tests on source columns"
    ```yaml
    tables:
      - name: table_name
        identifier: table_name
        columns:
          - name: column_name
            tests:
              - not_null
              - unique
    ```

    Run source tests:

    ```bash
    dbt test --select source:streaming
    ```

---

## Step 4 - Add source freshness config

- [ ] Step complete

Add a `loaded_at_field` and `freshness` block to at least one table (start with `watch_events`).

Add two new keys under the same level as the table in your source yaml:
- freshness
- loaded_at_field

Use autocomplete (tab) as this will auto populate what you need to add to configure the source freshness correctly.

??? tip "Hint: Freshness config"
    ```yaml
    tables:
      - name: table_name
        loaded_at_field: column_name
        freshness:
          warn_after: 
            count: int # Your tolerance, eg 4 days
            period: day/hour/minute/second
          error_after: 
            count: int # Your tolerance, eg 4 days
            period: day/hour/minute/second
    ```

    Test it with:

    ```bash
    dbt source freshness --select source:streaming
    ```

    dbt compares `max(watched_at)` against the current timestamp and raises a warning or error if data is older than the threshold.

---

## Step 5 - Build `stg_streaming__content_catalog.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__content_catalog.sql`. 

You can do this by clicking the `Generate model` button that appears above the name of your table in the source yaml you already created.

When the code is generated, click save - notice where this file is saved? Why is that?

**Goals**: Make the following changes to clean the data

- Rename columns to be clear and consistent
- Cast any data types that are incorrect
- Clean the string columns - notice any inconsistencies with casing or spaces?

??? tip "Hint: Try running the following - what do you see?"
    ```sql
    select 
        distinct genre
    from {{ source('streaming', 'content_catalog') }} 
    ```
    Are these values consistent?

    ```sql
    select 
        *
    from {{ source('streaming', 'content_catalog') }} 
    where genre = 'drama'
    ```
    How many rows did you expect to be returned? What is the issue?

    - `lower(trim(...))` can be used to normalise string values.

---

## Step 6 - Build `stg_streaming__subscriptions.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__subscriptions.sql`.

**Goals**: Make the following changes to clean the data

- Convert all cents columns to dollars 
- Normalize the `status` column and rename to `subscription_status`
- Create two new `timestamp` columns from the existing date and time columns
    - `started_at`: from `start_date` and `start_time`
    - `ended_at`: from `end_date` and `end_time`

??? tip "Hint: Handling cents conversion"
    ```sql
    column_in_cents / 100.0 as column_in_dollars
    ```

??? tip "Hint: Handling status column normalization"
    ```sql
    lower(trim(...)) as new_column
    ```

??? tip "Hint: Handling date columns"
    ```sql
    cast(column_date || ' ' || column_time as timestamp) as new_column_name,
    ```

---

## Step 7 - Build `stg_streaming__watch_events.sql`

- [ ] Step complete

Create `models/staging/streaming/stg_streaming__watch_events.sql`.

This is the highest-volume table - fact-style, one row per viewing event. The values in `event_id` are reused when the source data collects the event stream data. This means that this column is not unique.

??? tip "Hint: Using Snowflake's MD5 function"
    Snowflake's `MD5` function will create a hash key from a given value. To get one value you first need to concatencate the columns and then use the `MD5` function on that result - see below for an example.
    ```sql
    MD5(
        CONCAT(
            COALESCE(column_1, ''), '|',
            COALESCE(column_2, ''), '|',
            COALESCE(column_3, '')
        ) 
    ) AS hash_key,
    ```

---
## Step 8 - Create a staging models YAML

- [ ] Step complete

Create `models/staging/streaming/_streaming__models.yml`. 

You will use this to document all three staging models with (at a minimum) the following info and tests:

- A model-level description
- `not_null` + `unique` tests on the primary key column
- `not_null` tests on key foreign keys and timestamp columns

??? tip "Hint: Use the codegen package to generate the model yaml"

    [dbt-codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/) generates model YAML so you don't have to write it by hand.

    **1. Add the package to `packages.yml`** by adding the following two lines under `dbt_utils`:

    ```yaml
        - package: dbt-labs/codegen
            version: 0.13.1
    ```

    **2. Install it:** It should automatically install, however to manually do this you can run the following in the command line.

    ```bash
        dbt deps
    ```

    **3. Open a new (or existing) untitled file in dbt Cloud and paste the following, then click `</>` **Compile**:**

    ```sql
        {{ codegen.generate_model_yaml(
            model_names=["model_name"]
        ) }}
    ```

    Copy the compiled output into your `_streaming__models.yml` and fill in descriptions and any additional tests.


---

## Step 9 BONUS - Run the full test suite

- [ ] Step complete

To run all tests run:
- `dbt test --select source:streaming+`

To run *only* on the sources:
- `dbt test --select source:streaming`

To run *only* on the staging models:
- `dbt test --select staging.streaming`

Fix any failures. A test failure is information - read the error message, query the failing rows, understand why.

??? tip "Hint: Investigating a test failure"
    To see failing rows for any test:
    - navigate to the failing test and toggle `Debug logs`
    - find the code being executed to run the test (see below for an example)
    - copy and paste the code into an untitled file
    - run the code (preview) to see which rows are causing the tests to fail
    - decide on the best course of action to fix the failing tests

    Example SQL code:
    ```sql
    select
        content_id as unique_field,
        count(*) as n_records

    from MEDIAPULSE.streaming.content_ctlg
    where content_id is not null
    group by content_id
    having count(*) > 1
    ```

---

!!! success "Done?"
    You've added sources, source freshness checks, primary key built-in tests, creating staging models and used a common dbt package (`codegen`) to make your workflow more efficient.

    Now head to [Level 2](../level2/checklist.md) to continue applying new skills!
