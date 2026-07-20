# Exercise: Snowflake Optimization

## Background

Snowflake's storage and compute model is fundamentally different from traditional databases. Understanding how it physically organizes data — and how to exploit that — is the difference between a query that scans 100% of a table and one that scans 0.1%.

📖 [Snowflake micro-partitions](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)
📖 [Clustering keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys)
📖 [Automatic clustering](https://docs.snowflake.com/en/user-guide/tables-auto-reclustering)
📖 [Materialized views](https://docs.snowflake.com/en/user-guide/views-materialized)

---

## Micro-partitions: the basics

Snowflake automatically divides every table into micro-partitions of 50–500MB each (compressed). Each micro-partition stores column min/max values in metadata. When you run a query with a `WHERE` clause, Snowflake uses that metadata to **skip** entire micro-partitions that can't contain matching rows — without reading them.

This is called **partition pruning**. It's free and automatic, but only works well when data is **naturally ordered** by the filter column. If your most common query filters are `WHERE impression_date = '2024-01-15'`, but rows are stored in random order, Snowflake has to read everything.

---

## Your task

### 1. Understand your query patterns

Look at `fct_ad_impressions`. What are the most likely filter columns in production queries?

- Time-series dashboards: filter by `impression_date`
- Campaign reporting: filter by `campaign_id` or `campaign_type`
- Content attribution: filter by `content_id`

Which of these has the highest cardinality? Which would benefit most from clustering?

### 2. Add a clustering key in dbt

Clustering keys tell Snowflake to physically sort data by one or more columns, improving pruning on those columns. In dbt, add it to your model config:

```sql
{{ config(
    materialized='table',
    cluster_by=['impression_date', 'campaign_id']
) }}
```

📖 [dbt Snowflake cluster_by config](https://docs.getdbt.com/reference/resource-configs/snowflake-configs#configuring-table-clustering)

After running, check clustering depth:

```sql
select system$clustering_information('fct_ad_impressions');
```

What does `average_depth` tell you? What's an acceptable value?

### 3. Query the clustering information

Before and after adding a clustering key, compare query performance using the query profile in Snowflake:

```sql
-- Unoptimized scan
select sum(allocated_spend_cents)
from fct_ad_impressions
where impression_date = '2024-01-15';
```

Check the query profile: how many micro-partitions were scanned vs. pruned?

### 4. Automatic clustering

Snowflake can automatically maintain clustering as new data arrives — at ongoing compute cost. Evaluate whether automatic clustering is worth enabling:

- How often does `fct_ad_impressions` get refreshed?
- How large is the table? (Clustering is cost-effective at scale, overhead at small sizes)
- Is the table queried frequently enough to justify the cost?

### 5. Microbatch incremental strategy

The `microbatch` strategy (dbt 1.9+) is designed for event-stream tables like `fct_ad_impressions`. Instead of using a watermark, it processes data in fixed time windows and re-processes each window independently — making late-arriving data easy to handle.

📖 [Microbatch incremental strategy](https://docs.getdbt.com/docs/build/incremental-microbatch)

```sql
{{ config(
    materialized='incremental',
    strategy='microbatch',
    event_time='impression_date',
    begin='2024-01-01',
    batch_size='day'
) }}

select * from {{ ref('stg_ads__impressions') }}
```

Compare this to the `append` strategy in the current `fct_ad_impressions`. What problem does microbatch solve that append doesn't?

### 6. Materialized views

A materialized view pre-computes and caches query results in Snowflake. Unlike dbt `materialized='table'`, Snowflake materialized views are maintained **automatically and incrementally** as the base table changes.

When would you use a Snowflake materialized view instead of a dbt model?

- You need near-real-time results without running `dbt run` on a schedule
- The aggregation is expensive but the result is queried constantly
- You want Snowflake to maintain it, not your dbt job

Limitations to consider:
- Materialized views have significant [SQL restrictions](https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views)
- They add ongoing compute cost (auto-refresh runs on Snowflake's compute)
- dbt doesn't manage the refresh — you lose the dbt lineage graph for that object

---

## Discussion questions

- When would you choose clustering over partitioning? (Snowflake doesn't have traditional partitioning — micro-partitions are the equivalent.)
- At what table size does clustering start paying off vs. adding unnecessary cost?
- Microbatch vs. merge vs. append — make the case for each in the context of `fct_ad_impressions`.
- If Snowflake is doing automatic clustering, does that change how you design your staging models?
