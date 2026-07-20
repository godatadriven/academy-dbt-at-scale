# Group 3 - Multi-project Deployment Best Practices

Head to [Level 1](level1/checklist.md) when you are ready to start.

---

## Your slice of MediaPulse

You work **across both projects**: auditing and hardening `mediapulse_platform`, then wiring `mediapulse_analytics` to depend on the platform via dbt mesh. You also build out the revenue side of the analytics project.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Run **dbt-project-evaluator** against a real project and triage findings by risk
- Apply **elementary** package tests for anomaly detection on key models
- Define **model contracts** that enforce schema at run time
- Apply **model access** controls (`public`, `protected`, `private`) and **groups** to expose selected models to other projects
- Define **exposures** to document what downstream tools consume platform data
- Configure a cross-project ref (dbt mesh) so `mediapulse_analytics` consumes public models from `mediapulse_platform`
- Design and set up **dbt Cloud CI/CD jobs**: slim CI, nightly full-refresh, and production deploy
- Explain the trade-offs of each job trigger and selector
- Design and build a governed **fact table** from an existing intermediate model, deciding what to promote and what caveats to document

---

## Key concepts

### dbt-project-evaluator

A dbt package that runs a suite of models querying your project metadata and flags structural violations: missing tests, missing documentation, marts that join directly to raw sources, fan-out issues, and more.

Read the [dbt-project-evaluator documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/) before running it.

### Elementary

An open-source dbt package for data observability. It adds anomaly detection tests (volume, freshness, column-level statistics) and a run-history dashboard, all inside your dbt project.

Read the [elementary dbt package documentation](https://docs.elementary-data.com/data-tests/dbt/dbt-package).

### Model contracts and access

Model contracts enforce that a model's output schema matches its YAML definition at run time. Combined with model access controls, they form the governed interface that other projects depend on.

Read the [model contracts documentation](https://docs.getdbt.com/docs/mesh/govern/model-contracts) and the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access).

### Exposures

Exposures document what downstream tools (BI dashboards, notebooks, ML pipelines) consume your dbt models. They appear in the lineage DAG so you can see the full impact of a change.

Read the [exposures documentation](https://docs.getdbt.com/docs/build/exposures).

### dbt mesh and cross-project refs

dbt mesh is the architecture pattern for connecting multiple dbt projects. Once `mediapulse_platform` exposes public contracted models, `mediapulse_analytics` can reference them using:

```sql
{{ ref('mediapulse_platform', 'stg_news__articles') }}
```

Read the [dbt mesh introduction](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-1-intro) for the full guide.

### CI/CD in dbt Cloud

The goal is to catch problems as early as possible:

| Job | Trigger | Purpose |
|-----|---------|---------|
| Slim CI | PR opened or updated | Rebuild only changed models and downstream |
| Nightly full-refresh | Cron 02:00 | Full rebuild to catch schema drift |
| Production deploy | Merge to main | Run critical-path models and tests |

Read the [dbt Cloud CI jobs documentation](https://docs.getdbt.com/docs/deploy/ci-jobs).

---

## Relevant assets

| Asset | Location | Your task |
|-------|----------|-----------|
| Both dbt projects | `mediapulse_platform/` and `mediapulse_analytics/` | Audit, harden, and connect |
| `stg_*` models | `mediapulse_platform/models/staging/` | Add contracts and access controls |
| `fct_content_performance.sql` | `mediapulse_analytics/models/marts/content/` | Fix logic bug, wire cross-project ref |
| `fct_ad_revenue.sql` | `mediapulse_analytics/models/marts/revenue/` | Fix grain bug, complete the mart |
| `fct_ad_impressions.sql` | `mediapulse_platform/models/marts/ads/` | Missing - design and build this fact table |
| `seeds/commission_lookup.csv` | `mediapulse_analytics/seeds/` | Create this seed |
| `snapshots/snap_ads__campaigns` | `mediapulse_analytics/snapshots/` | Create this snapshot |
| `tests/` | `mediapulse_analytics/tests/` | Write singular tests |

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00 - 12:00) | Level 1: dbt-project-evaluator audit, triage findings |
| Day 1 PM (13:30 - 16:30) | Level 1: elementary tests; begin Level 2 (contracts, groups) |
| Day 2 AM (09:45 - 12:00) | Level 2: exposures, cross-project refs |
| Day 2 PM (13:00 - 15:30) | Level 3: CI/CD setup, presentation prep |
