# Group 2 - Checklist Level 2

## dbt Level Up

Start on this checklist once you have completed [Checklist Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Testing** — `relationships`, `accepted_values`, `not_null` gap-filling
- **Documentation** — YAML for your mart
- **Snapshots** — SCD Type 2 for slowly-changing article metadata

Work through the steps in order. Expand a hint only after you've had a genuine attempt — the struggle is where the learning happens!

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
    - name: author_id
      description: Foreign key to stg_news__authors.
      data_tests:
        - not_null
        - relationships:
            to: ref('stg_news__authors')
            field: author_id
    ```

??? tip "Hint: accepted_values example"
    ```yaml
    - name: status
      data_tests:
        - accepted_values:
            values: ['draft', 'published', 'archived']
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

??? tip "Hint"
    ```yaml
    version: 2

    models:
      - name: content_performance
        description: >
          One row per piece of content (article or podcast episode) published by MediaPulse,
          enriched with normalised category information.
        columns:
          - name: content_id
            description: Unique identifier — article_id for news, episode_id for podcasts.
            data_tests:
              - not_null
          - name: platform
            description: Which MediaPulse platform produced this content.
            data_tests:
              - not_null
              - accepted_values:
                  values: ['news', 'podcasts']
          - name: published_at
            data_tests:
              - not_null
    ```

---

## Step 4 - Create a snapshot for article metadata

- [ ] Step complete

Create `snapshots/snap_news__articles.sql`. This should track changes to article `title`, `category`, and `status` over time using the `timestamp` strategy.

??? tip "Hint: Snapshot block"
    ```sql
    {% snapshot snap_news__articles %}

    {{
        config(
            target_schema='snapshots',
            unique_key='article_id',
            strategy='timestamp',
            updated_at='updated_at',
        )
    }}

    select
        article_id,
        title,
        author_id,
        category,
        status,
        published_at,
        updated_at
    from {{ source('news', 'articles') }}

    {% endsnapshot %}
    ```

    Run it:

    ```bash
    dbt snapshot
    ```

    Check the output table. What columns did dbt add? (`dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`)

---

## Step 5 - Run the snapshot a second time (simulate a change)

- [ ] Step complete

To see the snapshot in action, update a row in the source (your facilitator can do this, or run an `UPDATE` if you have write access):

```sql
update news.articles
set status = 'archived', updated_at = current_timestamp
where article_id = (select article_id from news.articles limit 1);
```

Then run `dbt snapshot` again and query the snapshot table:

```sql
select * from snapshots.snap_news__articles
where dbt_valid_to is not null
order by dbt_updated_at desc
limit 5;
```

You should see the old row with a `dbt_valid_to` value and a new current row with `dbt_valid_to is null`.

??? tip "Hint: Reading snapshot output"
    | Column | Meaning |
    |--------|---------|
    | `dbt_valid_from` | When this version of the row became current |
    | `dbt_valid_to` | When this version was superseded (`NULL` = still current) |
    | `dbt_scd_id` | Surrogate key for this snapshot row |

---

## Step 6 - Run `dbt build --select +content_performance`

- [ ] Step complete

This builds the full lineage and runs all tests together.

```bash
dbt build --select +content_performance
```

Fix any remaining failures. A test failure is information — read the error, query the failing rows, understand why before changing anything.

---

## Step 7 - BONUS: Snapshot for podcast episodes

- [ ] Step complete

Create a snapshot for `podcasts.episodes` tracking changes to `title` and `duration_seconds`. Why might you want to track duration changes? (Episodes sometimes get re-edited and re-uploaded.)

---

!!! success "Done?"
    You've added relationship integrity checks, filled test gaps, documented your mart, and implemented SCD Type 2 for article metadata. These are the building blocks of a production-grade test suite — nicely done.

    Your work directly enables Group 3's revenue attribution — they need clean content data to allocate ad revenue correctly.
