# Exercise: Snapshots (SCD Type 2)

## What are snapshots?

Snapshots let dbt track row-level changes to a source table over time, storing each historical version as a separate row. This is Slowly Changing Dimension (SCD) Type 2 behaviour — every version of a record is preserved with valid-from / valid-to timestamps.

📖 [dbt Snapshots docs](https://docs.getdbt.com/docs/build/snapshots)

---

## The MediaPulse use case

The `news.articles` table has:

- `article_id` — stable primary key
- `title` — can be corrected post-publication
- `status` — `draft` → `published` → `archived`
- `updated_at` — timestamp updated whenever the row changes

This is a good SCD Type 2 candidate: you want to know **what an article's status was on a given day**, not just what it is now. Revenue attribution may depend on whether an article was `published` or `archived` at the time of an impression.

---

## Your task

### 1. Choose a strategy

dbt supports two snapshot strategies:

| Strategy | How it detects changes | Use when |
|---|---|---|
| `timestamp` | Compares `updated_at` to last run | Source has a reliable `updated_at` |
| `check` | Hashes `check_cols` values | No `updated_at`, or you don't trust it |

`news.articles` has `updated_at`. Which strategy should you use, and what are the failure modes if `updated_at` is not always updated when a row changes?

### 2. Write the snapshot

Create `snapshots/snap_news__articles.yml`. Snapshot the `stg_news__articles` model (use `ref()`, not `source()`), tracking `title`, `status`, and `category`.

Run:

```bash
dbt snapshot
```

Query the result:

```sql
select * from snapshots.snap_news__articles
order by article_id, dbt_valid_from;
```

### 3. Simulate a change

The `stg_news__articles` source has an `articles_updated` identifier you can point at. In `_news__sources.yml`, temporarily change:

```yaml
- name: articles
  identifier: articles_updated
```

Then re-run:

```bash
dbt run --select stg_news__articles
dbt snapshot
```

Query to see the change captured:

```sql
select *
from snapshots.snap_news__articles
where dbt_valid_to is not null
order by dbt_updated_at desc;
```

### 4. Consider the hard cases

Think through these scenarios with your group:

- **Hard deletes**: if a row is deleted from the source, what happens in the snapshot? How do you detect it? See [`invalidate_hard_deletes`](https://docs.getdbt.com/docs/build/snapshots#hard-deletes-opt-in).
- **Retroactive corrections**: a row's `updated_at` is backdated. Will the snapshot pick it up? What does this mean for historical reporting accuracy?
- **Snapshot velocity**: if a row changes twice between snapshot runs (e.g., `draft → published → archived` within an hour), only the latest state is captured. Is that acceptable for your use case?
- **Disaster recovery**: if the snapshot table is accidentally dropped, what can you do? What can't you recover?

---

## Discussion questions

- When is SCD Type 2 the right choice vs just keeping the latest state?
- What schema should snapshots live in — why not the same schema as marts?
- Would you snapshot a fact table? Why or why not?
