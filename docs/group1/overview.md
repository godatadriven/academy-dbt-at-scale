# Group 1 - Intermediate

## Your slice of MediaPulse

The `mediapulse_platform` project already exists, with a working `staging → intermediate → marts` layering across news, podcasts, streaming, and ads. Your job across today is to work *with* that project the way a new hire would: understand it via tooling before touching code, refresh your modeling fundamentals against real models, close real test gaps, eliminate real repetition with macros, and try dbt's AI assistant on real work.

Everything in Part 1 and Part 2 lives in `mediapulse_platform`. You won't need `mediapulse_analytics` today - that's Group 2 and Group 3's territory once dbt Mesh enters the picture.

---

## What gets covered

### Part 1

1. [dbt Catalog](1.1-dbt-catalog.md) - navigate a project you didn't build using lineage and metadata, not just by reading SQL
2. [Modeling refresh](1.2-modeling-refresh.md) - trace the staging → intermediate → marts pattern through real models and materializations
3. [Testing](1.3-testing.md) - find and close real, deliberate test coverage gaps, and diagnose a hidden data bug test-first
4. [Jinja & Macros](1.4-jinja-and-macros.md) - understand an existing custom macro and write your own to remove real repetition
5. [dbt Wizard](1.5-dbt-wizard.md) - use dbt's AI assistant against a real project task, and learn where to trust it and where not to

### Part 2

1. [Advanced testing](2.1-advanced-testing.md) - singular tests and `dbt_utils` generic tests for business-logic invariants that built-in tests can't express
2. [Snapshots](2.2-snapshots.md) - build the project's first snapshot to track a slowly-changing dimension
3. [Model governance](2.3-model-governance.md) - understand the access modifiers already configured in the project, then extend them with groups, contracts, and versions
4. [Incremental modeling](2.4-incremental-modeling.md) - convert a high-volume fact table so it stops fully rebuilding on every run

Each topic has an **Exercise** (apply the skill directly) and an **Extension** (apply it at a noticeably higher level of difficulty) - do the Extension if you finish the Exercise with time to spare.

---

## Learning objectives

By the end of today you will be able to:

- Navigate a project's lineage, test coverage, and documentation using **dbt Catalog**, without reading every file
- Explain what each layer of a staging → intermediate → marts project is responsible for, and argue where a piece of logic belongs
- Decide which columns genuinely need a test, write **generic**, **singular**, and `dbt_utils` tests, and configure test **severity**
- Read, and write, **Jinja macros** that remove real repetition in a project
- Build a **snapshot** with the correct change-detection strategy for a given column
- Explain what `access`, `group`, `contract`, and model **version** each do, and when to reach for each one
- Convert a model to **incremental**, justify a strategy choice, and know when a full-refresh is unavoidable
- Use **dbt Wizard** productively on a real task, and identify where its output needs your judgement

---

## Relevant project

You'll work exclusively in `mediapulse_platform`:

- `models/staging/` - news, podcasts, streaming, ads
- `models/intermediate/` - campaign spend allocation, episode listen completion
- `models/marts/` - campaigns, dates, and (by the end of today) your own snapshot and incremental additions

See the [MediaPulse overview](../mediapulse/overview.md) for the underlying business context and raw table details, and `mediapulse_platform/README.md` for the project's own structure notes.
