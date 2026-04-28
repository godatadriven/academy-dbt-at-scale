# Group 2 - Checklist Level 1

## dbt Fundamentals + Bug Fixing

Start here. The first four steps are about reading critically and fixing what's broken - resist the urge to skip straight to building. Understanding *why* a bug exists is more valuable than the fix itself.

In this level you will:

- **Read and fix existing staging models** with real production bugs
- **Create a seed** for a reference lookup table
- **Build a cross-domain mart** combining news and podcast content

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Add tests to `stg_news__articles.sql`


- [ ] Step complete

In the `_news__models.yml` ...

- what is the primary key of the `stg_news__articles` model?
- run `dbt test --select stg_news__articles` - what tests are already being executed?
- which built-in test is missing for a primary key? Add it and rerun the test command.

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
    dbt test --select staging.news
    ```

Once you have rerun the command, you should see some errors - find the code that is being executed to run this test in the `command history -> Debug logs`. Can you see why it has errored?

---

## Step 2 - Audit `stg_news__articles.sql`

- [ ] Step complete

Open `models/staging/news/stg_news__articles.sql` and read it carefully. Query the raw source to see if there are any data inconsistencies that should be treated in the staging model.

Look particularly at the article_id - is this unique? Use a window function to check.

Does the staging model handle this? What happens downstream if it doesn't?

??? tip "Hint: Use a window function to identify duplicates"
    Run the following:

    ```sql
    with window_article as (
        select 
            *, 
            count(*) over (partition by article_id) as cnt_article_id
        from news.articles
    )

    select * from window_article
    where cnt_article_id > 1
    order by article_id, published_at
    ```
    What is happening?
    
??? question "Why are there duplicates?"
    The raw `articles` table contains duplicate `article_id` values - articles get republished with a new `updated_at` timestamp. 
    Better yet... you can add a unique test to test uniqueness.
    
    
??? bug "Fix needed!"
    The current staging model selects `*` without deduplication. This means any downstream model joining on `article_id` will fan out and produce inflated row counts.

    You will apply this fix in the following step.

---

## Step 3 - Fix `stg_news__articles.sql`

- [ ] Step complete

Apply the deduplication fix. Keep only the most recent row per `article_id` (highest `updated_at`).

??? tip "Hint: Adapt the window function from step 1"

    Remember the code used to check for duplicates? How could this be adapted to **keep only the most up to date** version of the article (i.e. the one most recently (re)published)?

    ```sql
    with window_article as (
        select 
            *, 
            count(*) over (partition by article_id) as cnt_article_id
        from news.articles
    )

    select * from window_article
    where cnt_article_id > 1
    order by article_id, published_at
    ```

    After the fix, re-run the row count check against the staged model and confirm `article_id` is now unique.

??? example "Really stuck? Check this SQL here:"

    Here is a useful code snippets you can adapt for your needs. Read it through and make sure you an understand each part.

    ```sql
    with source as (
        select * from {{ source('source_name', 'table_name') }}
    ),

    deduped as (
        select *,
            row_number() over (
                partition by unique_id
                order by date_column desc
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

## Step 4 - Check for unique combination of columns

- [ ] Step complete

We have seen that the article_id in the raw data is not unique. However, new articles should only be added to the source when they were updated with a new updated_at timestamp. We can verify this by adding another data test on the uniqueness of the combination. 

Add the dbt_utils package to `packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.3
```

Run the following command in the CLI to load the packages.

```bash
dbt deps
```

Now add a test for the unique combination of `article_id` and `updated_at` to the source in `_news__sources.yml`.

??? tip "Hint: unique_combination_of_columns test"
    Add the test at the table level (not column level) in your `.yml` file:

    ```yaml
    tables:
      - name: table_name
        data_tests:
          - dbt_utils.unique_combination_of_columns:
              combination_of_columns:
                - column_one
                - column_two
    ```

---

## Step 5 - Create `seeds/category_mapping.csv`

- [ ] Step complete

Articles and podcast episodes both have a `category` column, but the values don't match what the end users expect. They have created the following mapping file for you:

```csv
category,category_group
politics,news_and_current_affairs
technology,tech_and_science
sport,sport_and_health
entertainment,arts_and_culture
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
4. Join the result to `category_mapping` (your seed) to get `category_group`

!!! warning "Check the existing stub first"
    Open `models/marts/content/content_performance.sql`. The existing stub uses a `JOIN` between articles and episodes - why is this the incorrect approach?

??? tip "Hint: Why the stub is wrong"
    The stub does:

    ```sql
    select ...
    from stg_news__articles a
    inner join stg_podcasts__episodes e on a.category = e.category
    ```

    This produces a cross-join of every article in a category with every episode in the same category - exactly the row explosion the dedup fix was meant to prevent elsewhere. Articles and episodes are separate content items; they should be stacked, not joined.

??? tip "Hint: The better approach"
    **What you're building:** A single unified content table that combines articles and podcast episodes, then enriches it with normalised category labels.

    1. Pull all articles from stg_news__articles
    2. Pull all episodes from stg_podcasts__episodes
    3. UNION ALL the two after normalising to a common schema
    4. Join the result to category_mapping (your seed) to get normalised_category and category_group

    Match the steps to build out the following CTEs

    **CTEs 1 & 2 - `articles` and `episodes`**  
    Pull from each staging model and rename columns into a shared schema that works for both content types. For columns that only apply to one content type, explicitly fill the other with a placeholder. Add a hardcoded column to identify which platform each row came from.

    > **Note:** Episodes don't have a `category` column — it lives on `stg_podcasts__shows`. Join `stg_podcasts__shows` into the `episodes` CTE on `show_id` to bring it in.

    **CTE 3 - `combined`**  
    Stack both CTEs into one dataset, keeping all rows from both.

    **CTE 4 - `with_category`**  
    Join to the `category_mapping` model. Use `coalesce` to return the mapped category where available, falling back to the raw value if not.

??? lab "Really stuck? See some example SQL:"
    Adapt the following SQL code to use a better combination for episodes and articles:

    ```sql 
    with articles as ( 
        select 
            article_id as content_id, 
            article_title as content_title, 
            published_at, 
            category as raw_category, 'news' as platform, 
            word_count as content_length_units, -- words for articles null as duration_seconds 
        from {{ ref('stg_news__articles') }} 
    ),

    episodes as (
        select
            -- ✏️ normalize columns that episodes have 
            -- in common to match the above
            

            -- ✏️ add columns that don't exist to match 
            -- the schema above


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
            -- ✏️ add the category group and 
            -- coalesce the category with raw_category


        from -- select the correct CTE
        left join -- add the seed reference
        using -- which column should you join on?
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

Fix any failures before moving on. A test failure is information - read the error message, query the failing rows, understand why.

---

!!! success "Done?"
    You've fixed two real production bugs and built a cross-domain content mart that unifies news and podcast data. Nice work.

    Now head to [Level 2](../level2/checklist.md) to add snapshots, improve test coverage, and document your models!

