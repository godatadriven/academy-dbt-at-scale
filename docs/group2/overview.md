# Group 2 - Advanced I

## Your slice of MediaPulse

The project you have seen before now splits in two. `mediapulse_analytics` is a second dbt project that doesn't own a staging layer of its own for `news`, `podcasts`, or `ads` - it reaches into `mediapulse_base` for that data via **dbt Mesh** using a cross-project dependency declared in `dependencies.yml`. 

Your team owns the `Streaming` and `Podcasts` section of MediaPulse. You will work within that area to develop your project and your dbt skills.

---

## What gets covered

### Part 1

1. [dbt Catalog & review](1.1-dbt-catalog-and-review.md) - a brisk recap of Catalog on `mediapulse_base`, then a full mesh-diagnosis exercise using Catalog's cross-project lineage view
2. [Advanced testing](1.2-advanced-testing.md) - singular tests and test configuration for business-logic invariants, pitched above Group 1's introductory testing pass
3. [Jinja/Macros & Custom schema logic](1.3-jinja-macros-and-custom-schema-logic.md) - unpack the project's real custom `generate_schema_name` macro and bring equivalent behaviour to `mediapulse_analytics`
4. [dbt Mesh](1.4-dbt-mesh.md) - what a project dependency actually is, how access levels gate what can cross the project boundary, and what's really being referenced today

### Part 2

1. [Project evaluation & further tests](2.1-project-evaluation-and-further-tests.md) - run `dbt-project-evaluator` against both projects and triage what it finds
2. [dbt Mesh](2.2-dbt-mesh.md) - continue into the mechanics of *when* a cross-project change actually becomes visible downstream
3. [Dynamic data masking](2.3-dynamic-data-masking.md) - a real, sensitive column in the project, and how Snowflake and dbt divide responsibility for protecting it
4. [Deployment & CI/CD](2.4-deployment-and-cicd.md) - design a CI/CD pipeline that accounts for two projects depending on each other

Each topic has an **Exercise** (apply the skill directly) and an **Extension** (apply it at a noticeably higher level of difficulty) - do the Extension if you finish the Exercise with time to spare.

---

## Learning objectives

By the end of today you will be able to:

- Use dbt Catalog's multi-project view to diagnose a bug that spans a project boundary, without reading the SQL first
- Write singular tests and configure **severity**/thresholds for situations that shouldn't hard-fail a build
- Explain what a custom `generate_schema_name` macro controls, and implement equivalent logic in a second project
- Explain the difference between a **package** dependency and a **project** dependency, and what `access: public` actually permits
- Run and interpret **`dbt-project-evaluator`** output across a single-project and a mesh-consuming project
- Explain where Snowflake's **dynamic data masking** and dbt's role in applying it begin and end
- Design a CI/CD approach (Slim CI, deferral) that accounts for a producer/consumer project relationship

---

## Relevant projects

You'll work across both:

- `mediapulse_base` - the producer project; note its `access` settings in `dbt_project.yml` and its `stg_news__authors.email` column
- `mediapulse_analytics` - the consumer project; its `dependencies.yml`, and its `fct_content_performance`/`fct_ad_revenue` marts that `ref()` across the mesh boundary

See the [MediaPulse overview](../mediapulse/overview.md) for the underlying business context, and each project's own `README.md` for how they're structured and how they relate to each other.
