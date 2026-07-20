# Group 4 - Power Users

Head to [Level 1](level1/checklist.md) when you are ready to start.

---

## Your mission

You are the most experienced group in the room. Your job is to go deep on multi-project architecture and dbt mesh, and to set a production-ready standard for the MediaPulse platform. You work across both dbt projects.

Further topics beyond the checklist levels will be agreed live with your facilitator based on where you are by Day 2 afternoon.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Design and implement **model contracts** that enforce schema and protect downstream consumers
- Apply **model access controls** and **groups** to govern which models are public across project boundaries
- Configure **cross-project references** (dbt mesh) so `mediapulse_analytics` consumes governed models from `mediapulse_platform`
- Reason about version strategy: when to use **model versions** vs just updating a model
- Design a **CI/CD pipeline** for a multi-project dbt setup
- Identify architectural trade-offs in a mesh deployment and defend your decisions
- Design and build a **fact table** that rolls up two source tables to a new grain via cross-project refs

---

## Key concepts

### Model contracts and access

Model contracts enforce that a model's output schema matches its YAML definition at run time. Model access controls determine which models are visible to other projects. Combined, they form the data contract boundary between teams.

Read the [model contracts documentation](https://docs.getdbt.com/docs/mesh/govern/model-contracts) and the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access).

### dbt mesh

dbt mesh is the architectural pattern for connecting multiple independent dbt projects via cross-project refs. Each project owns its slice and controls what it exposes.

Read the [dbt mesh introduction](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-1-intro).

### CI/CD in a multi-project setup

With two projects, CI/CD gets more interesting. Changes in `mediapulse_platform` can break `mediapulse_analytics` models if the contracts are not maintained. The job design needs to account for this dependency.

Read the [dbt Cloud CI jobs documentation](https://docs.getdbt.com/docs/deploy/ci-jobs).

---

## Relevant assets

| Asset | Location | Your task |
|-------|----------|-----------|
| Both dbt projects | `mediapulse_platform/` and `mediapulse_analytics/` | Add contracts, mesh, CI/CD |
| `stg_*` models | `mediapulse_platform/models/staging/` | Define contracts, set access levels |
| `fct_content_performance.sql` | `mediapulse_analytics/models/marts/content/` | Wire cross-project ref, fix logic |
| `fct_ad_revenue.sql` | `mediapulse_analytics/models/marts/revenue/` | Wire cross-project ref, fix grain |
| `fct_campaign_daily_performance.sql` | `mediapulse_analytics/models/marts/revenue/` | Missing - design and build this fact table |
| `dependencies.yml` | `mediapulse_analytics/` | Already created, ready to use |

---

## Further topics

!!! info "Further topics agreed live"
    This group is the most advanced. After completing the checklist, you will discuss further topics directly with your facilitator. Likely directions include deeper dbt mesh governance, model versioning, Semantic Layer integration, and dbt Wizard.

    See the [Extra Topics](../extra-topics.md) page for the semantic layer and dbt Wizard exercises, which you can pick up at any point.

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00 - 12:00) | Level 1: contracts, groups, access controls |
| Day 1 PM (13:30 - 16:30) | Level 2: cross-project refs, mesh setup |
| Day 2 AM (09:45 - 12:00) | Level 2 completion, Level 3 starts |
| Day 2 PM (13:00 - 15:30) | Level 3 and agreed further topics |
