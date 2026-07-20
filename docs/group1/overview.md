# Group 1 - Next Level dbt: StreamVault

Head to [Level 1](level1/checklist.md) when you are ready to start.

---

## Your slice of MediaPulse

You own the **StreamVault** data: MediaPulse's subscription streaming platform. The raw data exists in the database but the staging layer is empty. Your work lives in `mediapulse_platform`.

By the end of the workshop you will have a fully tested, documented staging layer for streaming data, a seed for reference data, snapshots for slowly changing dimensions, a suite of custom generic tests, and the streaming domain's fact table, `fct_streaming_engagement`.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Diagnose real dbt error messages and fix production bugs in existing models
- Define dbt **sources**, configure **source freshness**, and explain why both matter
- Build clean **staging models** that rename, cast, and normalise raw columns
- Create **seeds** for small reference datasets that belong in version control
- Apply **snapshots** to track how records change over time (SCD Type 2)
- Write **test configurations** using severity, `where`, and `store_failures`
- Author **custom generic tests** that are reusable across any model
- Design and build a **fact table** by joining your own staging models together at a grain you choose

---

## Key concepts

### Sources

Sources tell dbt about raw tables that live outside your project. They provide lineage tracking in the DAG, a place to document and test raw data before it enters your models, and freshness monitoring.

Read the [dbt sources documentation](https://docs.getdbt.com/docs/build/sources) before you write your source YAML.

### Generic tests

dbt ships with four built-in generic tests. You can also write your own.

| Test | What it checks |
|------|----------------|
| `not_null` | Column has no NULL values |
| `unique` | Column has no duplicate values |
| `accepted_values` | Column only contains values from a defined list |
| `relationships` | Every value in column A exists in column B |

Read the [dbt data tests documentation](https://docs.getdbt.com/docs/build/data-tests) for the full syntax.

### Seeds

Seeds are CSV files in your `seeds/` directory. Use them for small, slow-changing reference data that belongs in version control: lookup tables, category maps, rate tables.

Read the [dbt seeds documentation](https://docs.getdbt.com/docs/build/seeds).

### Snapshots

Snapshots implement SCD Type 2. Each time you run `dbt snapshot`, dbt compares the current source to the last snapshot and inserts a new version row for any changed record, closing out the previous one with `dbt_valid_to`.

Read the [dbt snapshots documentation](https://docs.getdbt.com/docs/build/snapshots).

### Custom generic tests

A custom generic test is a Jinja macro that accepts a model and any number of arguments, and returns a SQL query that returns rows when the test fails. Once defined, it can be applied to any model or column in YAML just like a built-in test.

Read the [custom generic tests guide](https://docs.getdbt.com/best-practices/writing-custom-generic-tests).

---

## Relevant tables

You will work with the `streaming` domain:

- `streaming.watch_events`
- `streaming.subscriptions`
- `streaming.content_catalog`

You will also fix bugs in the `news` and `podcasts` staging models at the start of Level 1.

See the [MediaPulse overview](../mediapulse/overview.md) and the [Platform project](../mediapulse/platform-overview.md) for full column details and the bug list.

You will also design `fct_streaming_engagement`, the streaming domain's missing fact table, once your staging layer, seed, and snapshot are in place.

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00 - 12:00) | Level 1: modeling refresh, bug fixes, sources, streaming staging |
| Day 1 PM (13:30 - 16:30) | Level 1 completion, Level 2: seeds and snapshots |
| Day 2 AM (09:45 - 12:00) | Level 3: test configurations and custom generic tests |
| Day 2 PM (13:00 - 15:30) | Level 3 completion, stretch tasks |
