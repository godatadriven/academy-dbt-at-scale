# Group 2 - Checklist Level 2

## dbt Level Up

Start on this checklist once you have completed [Checklist Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Testing** - `relationships`, `accepted_values`, `not_null` gap-filling
- **Documentation** - YAML for your mart
- **Snapshots** - SCD Type 2 for slowly-changing article metadata

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Review existing tests and identify gaps

- [ ] Step complete

Look at `_news__models.yml` and `_podcasts__models.yml`. Are the tests comprehensive? What's missing?

Make a note of at least two gaps you'd like to fill. You'll add them in Step 2.

??? tip "Hint: Common gaps to look for"
    - No `relationships` test linking `stg_news__articles.author_id` → `stg_news__authors.author_id`
    - No `not_null` test on `published_at` in episodes
    - No `accepted_values` on `status` in articles (`draft`, `published`, `archived`)
    - No `unique` test on `episode_id` in episodes

---

## Step 2 - Fill the test gaps

- [ ] Step complete

Go back to `_news__models.yml` and `_podcasts__models.yml` and add the missing tests you identified in Step 1.

Run them and understand any failures before fixing:

```bash
dbt test --select stg_news__articles stg_news__authors stg_podcasts__episodes
```

??? tip "Hint: Relationships test example"
    ```yaml
    - name: model_name
      description: Foreign key to # other model name here
      data_tests:
        - not_null
        - relationships:
            to: ref('model_name') # or source('source_name', 'table_name')
            field: column_name
    ```

??? tip "Hint: accepted_values example"
    Use the list structure in yaml - you have two options.

    Option 1:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            arguments:
                values: ['val1', 'val2', 'val3', ...]
    ```

    Option 2:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            arguments:
                - val1
                - val2
                - val3
                ...
    ```

    Run first to observe the failure, then decide: update the accepted list, or normalise the values in the staging model?

---

## Step 3 - Add a YAML file for the mart

- [ ] Step complete

Create `models/marts/content/_content__models.yml`. Document `content_performance` with descriptions and tests.

Include at minimum:

- A `not_null` test on `content_id`
- A `not_null` test on `platform`
- A `not_null` test on `published_at`
- An `accepted_values` test on `platform`

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

## Step 4 - Create a snapshot for article metadata

- [ ] Step complete

Create `snapshots/snap_news__articles.sql`. This should track changes to article `title`, `category`, and `status` over time using the `timestamp` strategy.

You can run this snapshot on the source data using the `source()` macro.

??? tip "Hint: Snapshot block"

    Add the following yaml

    ```yaml

    snapshots:
      - name: <string> # the name of your snapshot
        +relation: source('my_source', 'my_table') | ref('my_model')
        +database: <string>
        +schema: <string>
        +alias: <string>
        +unique_key: <column_name_or_expression>
        +strategy: timestamp | check # choose the most appropriate
        +updated_at: <column_name> # only when timestamp strategy is selected
        +check_cols: [<column_name>] | all # only when timestamp strategy is selected
        +dbt_valid_to_current: <string> # default is NULL
        +hard_deletes: 'ignore' | 'invalidate' | 'new_record' # default is ignore
    ```

    Run it:

    ```bash
    dbt snapshot
    ```

    Check the output table. What columns did dbt add? (`dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`)

---

## Step 5 - Run the snapshot a second time (simulate a change)

- [ ] Step complete

To see the snapshot in action, update the underlying source table name to point to the updated table:
```yaml
- name: articles
  identifier: articles_updated # add this into the source yaml file
```

!!! warning "Note: In practice the underlying source table would change, and you would not change any reference in dbt!!"

Then run `dbt snapshot` again and query the snapshot table:

```sql
select * from snapshots.snap_news__articles
where dbt_valid_to is not null
order by dbt_updated_at desc
```

You should see the old row with a `dbt_valid_to` value and a new current row with `dbt_valid_to is null`.

??? tip "Hint: Reading snapshot output"
    | Column | Meaning |
    |--------|---------|
    | `dbt_valid_from` | When this version of the row became current |
    | `dbt_valid_to` | When this version was superseded (`NULL` = still current) |
    | `dbt_scd_id` | Surrogate key for this snapshot row |

---

## Step 6 - Run dbt build

- [ ] Step complete

This builds the full lineage and runs all tests together.

```bash
dbt build --select +content_performance
```

Fix any remaining failures. A test failure is information - read the error, query the failing rows, understand why before changing anything.

---

## Step 7 - BONUS: Snapshot for podcast episodes

- [ ] Step complete

Create a snapshot for `podcasts.episodes` tracking changes to `title` and `duration_seconds`. Why might you want to track duration changes?

You can follow the same steps as above, using the "updated" data for episodes.

---

!!! success "Done?"
    You've added relationship integrity checks, filled test gaps, documented your mart, and implemented SCD Type 2 for article metadata. These are the building blocks of a production-grade test suite - nicely done.

    Your work directly enables Group 3's revenue attribution - they need clean content data to allocate ad revenue correctly.

    Now head to [Level 3](../level3/checklist.md) to configure your tests with severity, `where` clauses, and statistical guardrails from `dbt_expectations`!

