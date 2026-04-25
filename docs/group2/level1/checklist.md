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

??? tip "Hint 1: Useful SQL snippets"

    Here are some useful code snippets you can adapt for your needs:

    ```sql
    select *,
        row_number() over (
            partition by /*column_name*/
            order by /*column_name*/ desc
        ) as row_num
    from /*table_name*/
    ```

    ```sql
    where row_num = 1
    ```

    After the fix, re-run the row count check against the staged model and confirm `article_id` is now unique.

??? tip "Hint 2: ROW_NUMBER() dedup pattern"

    Here are some useful code snippets you can adapt for your needs:

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
            -- column cleaning
        from deduped
        where row_num = 1
    )

    select * from renamed
    ```

    After the fix, re-run the row count check against the staged model and confirm `article_id` is now unique.

---

## Step 3 - Audit `stg_podcasts__episodes.sql`

- [ ] Step complete

Open `models/staging/podcasts/stg_podcasts__episodes.sql` and try to run it.

Read the error message and then inspect the raw table:

```sql
select * from podcasts.episodes
```

What is the issue?

??? tip "Hint: The bug"
    The staging model references the wrong column name in its `SELECT` clause - can you spot which one? 

    **The fix:** replace the name of the column in the staging file to fix it.

Say you want to list all episodes ordered chronologically. 

Query the staging model and order by the column `season_episode`. What issue do you see? Go back to the staging model to correct this.

??? tip "Hint: What is happening?"
    The bug: season_episode is a string like '1-3', '2-3', '3-3' where the episode is the first value and the season the second. This is causing two issues:
    - When ordering the primary order is from the episode title. Meaning all episode 1s will be together from all seasons, then episode 2s etc.
    — Even if fixed, since this is a string, '3-10' will come before '3-9' because '1' < '9' as characters. Any downstream model ordering by `season_episode` will silently return episodes in the wrong order.

    It won't error, the values look completely reasonable at a glance, and the second problem only becomes visible once you have `10+` episodes in a season. Does that feel like the right difficulty level?

---

## Step 4 - Fix `stg_podcasts__episodes.sql`

- [ ] Step complete

Apply the fixes:
- Correct the name of the column
- Split out the season_episode to be two columns. Make sure to select the right number!
    - season
    - episode

```bash
dbt run --select stg_podcasts__episodes
dbt test --select stg_podcasts__episodes
```

??? tip "Hint: Syntax needed"
    ```sql
    split_part(column_name, '-', 1)::int as new_column_name,
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
        +schema: schema_name # choose where the seeds should land in the warehouse
        category_mapping:
          +column_types:
            column_name: # add a data type, eg varchar(50)
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
    Open `models/marts/content/content_performance.sql`. The existing stub uses a `JOIN` between articles and episodes - why is this the incorrect approach?

??? tip "Hint: Why the stub is wrong"
    The stub does:

    ```sql
    select ...
    from stg_news__articles a
    inner join stg_podcasts__episodes e on a.category = e.category
    ```

    This produces a cross-join of every article in a category with every episode in the same category — exactly the row explosion the dedup fix was meant to prevent elsewhere. Articles and episodes are separate content items; they should be stacked, not joined.

??? tip "Hint: The better approach"
    **What you're building:** A single unified content table that combines articles and podcast episodes, then enriches it with normalised category labels.

    **CTEs 1 & 2 — `articles` and `episodes`**  
    Pull from each staging model and rename columns into a shared schema that works for both content types. For columns that only apply to one content type, explicitly fill the other with a placeholder. Add a hardcoded column to identify which platform each row came from.

    **CTE 3 — `combined`**  
    Stack both CTEs into one dataset, keeping all rows from both.

    **CTE 4 — `with_category`**  
    Join to the `category_mapping` model on two conditions. Keep all content rows regardless of whether a mapping exists. Use `coalesce` to return the mapped category where available, falling back to the raw value if not.

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

