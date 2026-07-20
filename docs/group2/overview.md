# Group 2 - Optimization and Best Practices: Content Performance

Head to [Level 1](level1/checklist.md) when you are ready to start.

---

## Your slice of MediaPulse

You own the **content performance** story: how MediaPulse's editorial products (NewsNow articles and PodcastHub episodes) perform together. Your work lives primarily in `mediapulse_platform`.

The staging layer for both domains exists but has known bugs. The `fct_content_performance` mart in `mediapulse_analytics` has a logic error too. Your job is to bring the whole pipeline up to production standard while also applying best practices, incremental loading, and Jinja macros - and to design the fact table this domain is still missing.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Identify and apply **dbt modeling best practices** across a real project
- Implement an **incremental model** with the right strategy for a high-volume event table
- Explain the trade-offs between `append`, `merge`, and `insert_overwrite`
- Use **Jinja** in dbt models to eliminate repetition and write cleaner SQL
- Write and apply **macros** that are reusable across models, including one that switches the target schema by environment
- Author **custom generic tests** that express business rules once and apply them anywhere
- Design and build a **fact table** from event-grain source data, choosing the right grain yourself

---

## Key concepts

### dbt modeling best practices

Good dbt projects follow consistent patterns: one staging model per source table, only `ref()` and `source()` references (no raw SQL table names in models), clear naming conventions, and tests on every primary key. Read through the current staging models critically before building.

### Incremental models

An incremental model processes only new or changed rows on subsequent runs, making it practical for high-volume fact tables. The correct strategy depends on whether source rows can be updated after they are first written.

Read the [incremental models documentation](https://docs.getdbt.com/docs/build/incremental-models) before choosing a strategy.

### Jinja and macros

dbt models are Jinja templates. Macros let you define reusable SQL snippets that can be called from any model. A `generate_schema_name` macro can change the target schema based on the dbt `target` environment, which is essential for keeping dev and prod outputs separate.

Read the [Jinja and macros documentation](https://docs.getdbt.com/docs/build/jinja-macros) for the full reference.

### Custom generic tests

A custom generic test is written once as a Jinja macro and applied across any model or column in YAML. This is how you encode a business rule once and get dbt to enforce it everywhere.

Read the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests).

---

## Relevant tables and existing models

| Asset | Location | Status |
|-------|----------|--------|
| `news.articles` | Source | Has duplicate article_ids |
| `news.authors` | Source | Clean |
| `news.page_views` | Source | High volume, event data |
| `podcasts.episodes` | Source | Column name quirk |
| `podcasts.shows` | Source | Clean |
| `podcasts.listens` | Source | High volume, event data |
| `stg_news__articles.sql` | `mediapulse_platform/models/staging/news/` | Has a bug |
| `stg_news__authors.sql` | `mediapulse_platform/models/staging/news/` | Complete |
| `stg_podcasts__episodes.sql` | `mediapulse_platform/models/staging/podcasts/` | Has a bug |
| `stg_podcasts__shows.sql` | `mediapulse_platform/models/staging/podcasts/` | Complete |
| `fct_content_performance.sql` | `mediapulse_analytics/models/marts/content/` | Logic bug: wrong join |
| `fct_content_engagement.sql` | `mediapulse_platform/models/marts/content/` | Missing - your Level 3 capstone |

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00 - 12:00) | Level 1: best practices review, fix staging bugs |
| Day 1 PM (13:30 - 16:30) | Level 1: incremental model for page views |
| Day 2 AM (09:45 - 12:00) | Level 2: Jinja review and macros |
| Day 2 PM (13:00 - 15:30) | Level 3: custom generic tests |
