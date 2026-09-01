# Group 2 - Advanced I

## Your slice of MediaPulse

The project you have seen before now splits in two. `mediapulse_analytics` is a second dbt project that doesn't own a staging layer of its own for `news`, `podcasts`, or `ads` - it reaches into `mediapulse_base` for that data via **dbt Mesh** using a cross-project dependency declared in `dependencies.yml`. 

Your team owns the `Streaming` and `Podcasts` section of MediaPulse. You will work within that area to develop your project and your dbt skills.

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
