# Group 1 - Intermediate: StreamVault

This page will give you context for your use case.

Head to the [Checklist 1](level1/checklist.md) when you're ready to start.

## Testing, Sources, Jinja & Macros

## Your slice of MediaPulse

You own the **StreamVault** data - MediaPulse's subscription streaming platform. The raw data exists in the database but nobody has wired it into the dbt project yet. By the end of today you'll have a fully tested, documented staging layer for streaming data, complete with reusable macros.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Define dbt **sources** and explain why they matter
- Configure **source freshness** checks
- Write **generic tests** (`not_null`, `unique`, `accepted_values`, `relationships`)
- Build clean **staging models** that rename, cast, and normalise raw columns
- Utilize existing useful dbt packages to elevate your way of working with dbt
- Write and use **Jinja macros** to eliminate repetition
- Run `dbt test` and interpret failures

---

## Key concepts

### Sources

Sources tell dbt about raw tables that live outside your project. They give you:

- A place to document and test raw data before it enters your models
- `source()` references that show lineage in the DAG
- Freshness monitoring via `loaded_at_field`

### Generic tests

Four built-in generic tests cover most quality checks:

| Test | What it checks |
|------|---------------|
| `not_null` | Column has no `NULL` values |
| `unique` | Column has no duplicate values |
| `accepted_values` | Column only contains values from a defined list |
| `relationships` | Every value in column A exists in column B |

### Jinja & Macros

dbt models are Jinja templates. Macros let you define reusable SQL snippets. A macro is just a function:

```sql
{% macro cents_to_dollars(column_name) %}
    {{ column_name }} / 100.0
{% endmacro %}
```

Call it in a model:

```sql
select
    {{ cents_to_dollars('monthly_fee_cents') }} as monthly_fee
```

---

## Relevant tables

You'll work exclusively with `streaming`:

- `streaming.watch_events`
- `streaming.subscriptions`
- `streaming.content_catalog`

See the [MediaPulse overview](../mediapulse/overview.md) for full column details.

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00–12:00) | Steps 1–6: sources, freshness, first staging model |
| Day 1 PM (13:30–16:30) | Steps 7–13: remaining models, macros, full test suite |
