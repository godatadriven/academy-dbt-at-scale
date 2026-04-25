# Group 2 - Checklist Level 1

## dbt Fundamentals + Bug Fixing

Start here. The first four steps are about reading critically and fixing what's broken — resist the urge to skip straight to building. Understanding *why* a bug exists is more valuable than the fix itself.

In this level you will:

- **Read and fix existing staging models** with real production bugs
- **Create a seed** for a reference lookup table
- **Build a cross-domain mart** combining news and podcast content

Work through the steps in order. Expand a hint only after you've had a genuine attempt — the struggle is where the learning happens!

---

## Step 1 - Audit `stg_news__articles.sql`

- [ ] Step complete

Open `models/staging/news/stg_news__articles.sql` and read it carefully. Then query the raw source:

```sql
select article_id, count(*) as cnt
from news.articles
group by 1
having count(*) > 1
order by 2 desc
```

Does the staging model handle this? What happens downstream if it doesn't?

??? tip "Hint: What to look for"
    The raw `articles` table contains duplicate `article_id` values — articles get republished with a new `updated_at` timestamp. The current staging model selects `*` without deduplication. This means any downstream model joining on `article_id` will fan out and produce inflated row counts.

    **The fix:** use a `ROW_NUMBER()` window function to keep only the most recent version of each article.

---

## Step 2 - Fix `stg_news__articles.sql`

- [ ] Step complete

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

## Step 3 - Audit `stg_podcasts__episodes.sql`

- [ ] Step complete

Open `models/staging/podcasts/stg_podcasts__episodes.sql` and try to run it:

```bash
dbt run --select stg_podcasts__episodes
```

Read the error message. Then inspect the raw table:

```sql
select * from podcasts.episodes limit 5;
```

What column name does the raw table actually use?

??? tip "Hint: The bug"
    The staging model references `episode_name` in its `SELECT` clause, but the raw table column is named `title`. This causes a compilation error.

    **The fix:** replace `episode_name` with `title` (and alias it appropriately, e.g. `title as episode_title`).

---

## Step 4 - Fix `stg_podcasts__episodes.sql`

- [ ] Step complete

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

## Step 5 - Create `seeds/category_mapping.csv`

- [ ] Step complete

Articles and podcast episodes both have a `category` column, but the values don't match (`news` uses `politics`, `podcasts` uses `Politics`). Create a seed that maps raw category values to a normalised label and a display-friendly group.

```csv
category,platform,normalised_category,category_group
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
            category: varchar(100)
            platform: varchar(50)
            normalised_category: varchar(100)
            category_group: varchar(100)
    ```

    Then load it:

    ```bash
    dbt seed --select category_mapping
    ```

---

## Step 6 - Build `content_performance.sql`

- [ ] Step complete

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
            category,
            'news'          as platform,
            word_count      as content_length_units,
            null            as duration_seconds
        from {{ ref('stg_news__articles') }}
    ),

    episodes as (
        select
            episode_id      as content_id,
            episode_title   as content_title,
            published_at,
            null            as category,
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
            coalesce(cm.normalised_category, lower(c.category)) as normalised_category,
            cm.category_group
        from combined c
        left join {{ ref('category_mapping') }} cm
            on c.category = cm.category
            and c.platform = cm.platform
    )

    select * from with_category
    ```

---

## Step 7 - BONUS: Run `dbt build --select +content_performance`

- [ ] Step complete

This builds the entire upstream lineage of your mart plus the mart itself, then runs all tests.

```bash
dbt build --select +content_performance
```

Fix any failures before moving on. A test failure is information — read the error message, query the failing rows, understand why.

---

!!! success "Done?"
    You've fixed two real production bugs and built a cross-domain content mart that unifies news and podcast data. Nice work.

    Now head to [Level 2](../level2/checklist.md) to add snapshots, improve test coverage, and document your models!
