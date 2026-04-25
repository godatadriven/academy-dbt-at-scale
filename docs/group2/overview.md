# Group 2 - Advanced I: Seeds, Snapshots & Test Review

## Your slice of MediaPulse

You own the **content performance** story - how MediaPulse's editorial products (**NewsNow** articles and **PodcastHub** episodes) are performing together. The staging layer for both domains exists, but it has bugs. Your mart needs to join both, enriched with a category mapping seed, and you need to track how article metadata changes over time using a snapshot.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Read existing dbt models critically and **identify bugs**
- Create and load **seeds** - static reference data managed in version control
- Build a **mart** that joins across staging domains
- Create a **snapshot** to track slowly-changing dimensions (SCD Type 2)
- Write thorough **relationship tests** and document columns in YAML

---

## Key concepts

### Seeds

Seeds are CSV files in your `seeds/` directory. Use them for small, slow-changing reference data that belongs in version control (lookup tables, category maps, region codes).

```bash
dbt seed              # loads all seeds
dbt seed --select category_mapping  # loads one
```

### Snapshots

Snapshots implement SCD Type 2 - they track how a row changes over time by appending new versions rather than overwriting.

```sql
{% snapshot snap_articles %}
{{
    config(
        target_schema='snapshots',
        unique_key='article_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}
select * from {{ source('news', 'articles') }}
{% endsnapshot %}
```

Every time you run `dbt snapshot`, dbt compares the current source to the last snapshot and inserts a new row for any changed record, populating `dbt_valid_from` and `dbt_valid_to`.

### Reviewing existing models

Before building, always audit what's already there:

1. Read the model SQL - does it do what the filename implies?
2. Check column names against the raw source
3. Look for missing deduplication on high-volume sources
4. Run the model; do the row counts look right?

---

## Relevant tables & existing models

| Asset | Location | Status |
|-------|----------|--------|
| `news.articles` | Source | Has duplicates |
| `news.authors` | Source | Clean |
| `podcasts.episodes` | Source | Column name quirk |
| `podcasts.shows` | Source | Clean |
| `stg_news__articles.sql` | `models/staging/news/` | ❓ unknown status |
| `stg_news__authors.sql` | `models/staging/news/` | ✅ complete |
| `stg_podcasts__episodes.sql` | `models/staging/podcasts/` | ❓ unknown status |
| `stg_podcasts__shows.sql` | `models/staging/podcasts/` | ✅ complete |
| `content_performance.sql` | `models/marts/content/` | ❓ unknown status |

See the [MediaPulse overview](../mediapulse/overview.md) for the raw column details and the documented known bugs.

---

## Begin 

Head to the [Checklist](checklist.md) when you're ready to start.
