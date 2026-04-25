# Group 2 — Checklist

Work through the steps in order. The first five steps are about reading critically and fixing what's broken — resist the urge to skip straight to building new things.

---

## Step 1 — Audit `stg_news__articles.sql`

Open `models/staging/news/stg_news__articles.sql` and read it carefully. Then query the raw source:

```sql
select article_id, count(*) as cnt
from raw_news.articles
group by 1
having count(*) > 1
order by 2 desc
limit 20;
```

Does the staging model handle this? What happens downstream if it doesn't?

??? tip "Hint: What to look for"
    The raw `articles` table contains duplicate `article_id` values — articles get republished with a new `updated_at` timestamp. The current staging model selects `*` without deduplication. This means any downstream model joining on `article_id` will fan out and produce inflated row counts.

    **The fix:** use a `ROW_NUMBER()` window function to keep only the most recent version of each article.

---

## Step 2 — Fix `stg_news__articles.sql`

Apply the deduplication fix. Keep only the most recent row per `article_id` (highest `updated_at`).

??? tip "Hint: ROW_NUMBER() dedup pattern"
    ```sql
    with source as (
        select * from {{ source('news', 'articles') }}
    ),

    deduped as (
        select *,
            row_number() over (
                partition by article_id
                order by updated_at desc
            ) as row_num
        from source
    ),

    renamed as (
        select
            article_id,
            title           as article_title,
            author_id,
            category,
            cast(published_at as timestamp)  as published_at,
            cast(updated_at as timestamp)    as updated_at,
            status,
            word_count
        from deduped
        where row_num = 1
    )

    select * from renamed
    ```

    After the fix, re-run the row count check against the staged model and confirm `article_id` is now unique.

---

## Step 3 — Audit `stg_podcasts__episodes.sql`

Open `models/staging/podcasts/stg_podcasts__episodes.sql` and try to run it:

```bash
dbt run --select stg_podcasts__episodes
```

Read the error message. Then inspect the raw table:

```sql
select * from raw_podcasts.episodes limit 5;
```

What column name does the raw table actually use?

??? tip "Hint: The bug"
    The staging model references `episode_name` in its `SELECT` clause, but the raw table column is named `title`. This causes a compilation error.

    **The fix:** replace `episode_name` with `title` (and alias it appropriately, e.g. `title as episode_title`).

---

## Step 4 — Fix `stg_podcasts__episodes.sql`

Apply the column name fix and re-run:

```bash
dbt run --select stg_podcasts__episodes
dbt test --select stg_podcasts__episodes
```

??? tip "Hint: Full fixed model"
    ```sql
    with source as (
        select * from {{ source('podcasts', 'episodes') }}
    ),

    renamed as (
        select
            episode_id,
            show_id,
            title                              as episode_title,
            cast(published_at as timestamp)    as published_at,
            duration_seconds,
            season,
            episode_number
        from source
    )

    select * from renamed
    ```

---

## Step 5 — Review existing tests across news & podcasts

Look at `_news__models.yml` and `_podcasts__models.yml`. Are the tests comprehensive? What's missing?

Make a note of at least two gaps you'd like to fill. You'll come back to add them in Step 11.

??? tip "Hint: Common gaps to look for"
    - No `relationships` test linking `stg_news__articles.author_id` → `stg_news__authors.author_id`
    - No `not_null` test on `published_at` in episodes
    - No `accepted_values` on `status` in articles (`draft`, `published`, `archived`)
    - No `unique` test on `episode_id` in episodes

---

## Step 6 — Create `seeds/category_mapping.csv`

Articles and podcast episodes both have a `category` column, but the values don't match (news uses `politics`, podcasts use `Politics`). Create a seed that maps raw category values to a normalised label and a display-friendly group.

```csv
raw_category,platform,normalised_category,category_group
politics,news,politics,news_and_current_affairs
Politics,podcasts,politics,news_and_current_affairs
technology,news,technology,tech_and_science
Technology,podcasts,technology,tech_and_science
sport,news,sport,sport_and_health
Sports,podcasts,sport,sport_and_health
entertainment,news,entertainment,arts_and_culture
Entertainment,podcasts,entertainment,arts_and_culture
```

Place this file at `seeds/category_mapping.csv`.

??? tip "Hint: Adding a seed config"
    In `dbt_project.yml`, you can configure the seed's schema and column types:

    ```yaml
    seeds:
      mediapulse:
        +schema: seeds
        category_mapping:
          +column_types:
            raw_category: varchar(100)
            platform: varchar(50)
            normalised_category: varchar(100)
            category_group: varchar(100)
    ```

    Then load it:

    ```bash
    dbt seed --select category_mapping
    ```

---

## Step 7 — Build `content_performance.sql`

Create `models/marts/content/content_performance.sql`. This mart should:

1. Pull all articles from `stg_news__articles`
2. Pull all episodes from `stg_podcasts__episodes`
3. `UNION ALL` the two after normalising to a common schema
4. Join the result to `category_mapping` (your seed) to get `normalised_category` and `category_group`

!!! warning "Check the existing stub first"
    Open `models/marts/content/content_performance.sql`. The existing stub attempts a `JOIN` between articles and episodes — this is wrong. Understand why, then rewrite it.

??? tip "Hint: Why the stub is wrong"
    The stub does:

    ```sql
    select ...
    from stg_news__articles a
    inner join stg_podcasts__episodes e on a.category = e.category
    ```

    This produces a cross-join of every article in a category with every episode in the same category — exactly the row explosion the dedup fix was meant to prevent elsewhere. Articles and episodes are separate content items; they should be stacked, not joined.

??? tip "Hint: UNION ALL approach"
    ```sql
    with articles as (
        select
            article_id      as content_id,
            article_title   as content_title,
            published_at,
            category        as raw_category,
            'news'          as platform,
            word_count      as content_length_units,  -- words for articles
            null            as duration_seconds
        from {{ ref('stg_news__articles') }}
    ),

    episodes as (
        select
            episode_id      as content_id,
            episode_title   as content_title,
            published_at,
            -- note: podcasts category comes from shows join — simplified here
            null            as raw_category,
            'podcasts'      as platform,
            null            as content_length_units,
            duration_seconds
        from {{ ref('stg_podcasts__episodes') }}
    ),

    combined as (
        select * from articles
        union all
        select * from episodes
    ),

    with_category as (
        select
            c.*,
            coalesce(cm.normalised_category, lower(c.raw_category)) as normalised_category,
            cm.category_group
        from combined c
        left join {{ ref('category_mapping') }} cm
            on c.raw_category = cm.raw_category
            and c.platform    = cm.platform
    )

    select * from with_category
    ```

---

## Step 8 — Create a snapshot for article metadata

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

## Step 9 — Run the snapshot a second time (simulate a change)

To see the snapshot in action, update a row in the source (your facilitator can do this, or you can run a `UPDATE` statement if you have write access to the raw schema):

```sql
update raw_news.articles
set status = 'archived', updated_at = current_timestamp
where article_id = (select article_id from raw_news.articles limit 1);
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
    | `dbt_valid_to` | When this version was superseded (NULL = still current) |
    | `dbt_scd_id` | Surrogate key for this snapshot row |

---

## Step 10 — Add a YAML file for the mart

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
            tests:
              - not_null
          - name: platform
            description: Which MediaPulse platform produced this content.
            tests:
              - not_null
              - accepted_values:
                  values: ['news', 'podcasts']
          - name: published_at
            tests:
              - not_null
    ```

---

## Step 11 — Fill the test gaps you noted in Step 5

Go back to `_news__models.yml` and `_podcasts__models.yml` and add the missing tests you identified earlier.

??? tip "Hint: Relationships test example"
    ```yaml
    - name: author_id
      description: Foreign key to stg_news__authors.
      tests:
        - not_null
        - relationships:
            to: ref('stg_news__authors')
            field: author_id
    ```

---

## Step 12 — Run `dbt build --select +content_performance`

This builds the entire upstream lineage of your mart plus the mart itself, then runs all tests.

```bash
dbt build --select +content_performance
```

Fix any failures before moving on.

---

## Step 13 — BONUS: Investigate the snapshot for episodes

Create a snapshot for `raw_podcasts.episodes` tracking changes to `title` and `duration_seconds`. Why might you want to track duration changes? (Episodes sometimes get re-edited and re-uploaded.)

!!! success "Done?"
    You've fixed real bugs, built a cross-domain content mart, implemented SCD Type 2 for article metadata, and hardened the test suite. Your work directly enables Group 3's revenue attribution — they need clean content data to allocate ad revenue correctly.
