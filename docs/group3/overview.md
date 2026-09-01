# Group 3 - Advanced II

## Your slice of MediaPulse

This is the deepest track in the workshop. You're assumed comfortable with generic and singular testing and the shape of a dbt Mesh setup already - today is about auditing coverage systematically across both projects, closing real governance gaps between what a model's documentation promises and what its configuration actually allows, designing CI/CD and unit tests for business logic that genuinely matters, and confronting the operational edges of a two-project setup that access levels alone don't solve.

---

## Learning objectives

By the end of today you will be able to:

- Use dbt Catalog's project recommendations to prioritise real, project-wide test and documentation gaps, and judge which are acceptable-by-design
- Systematically audit test coverage across a project you didn't build, and explain what `relationships` tests can and can't validate across a dbt Mesh project boundary
- Design a CI/CD pipeline (Slim CI, deferral, job triggers) for two dbt projects that depend on each other
- Identify a real mismatch between a model's documented intent and its access configuration, and fix it with the correct governance mechanism (project-level default vs. per-model override)
- Design a new, genuinely cross-project model end to end, including the governance (access, groups, contracts, versions) it would need before being treated as stable
- Write tests that check internal consistency between two columns derived from the same business logic
- Write a **unit test** with mocked `given`/`expect` inputs for conditional SQL logic, and explain why some models in a mesh can't be unit tested the way a single-project model can

---

## Relevant projects

You'll work across both, more deeply than Group 2:

- `mediapulse_base` - specifically `dim_campaigns` (check its documentation against its actual access config) and the intermediate models' conditional business logic
- `mediapulse_analytics` - specifically the `crm` and `streamview_legacy` domains (fully self-contained, no mesh dependency) versus `fct_content_performance`/`fct_ad_revenue` (mesh-consuming)

See the [MediaPulse overview](../mediapulse/overview.md) for the underlying business context, and each project's own `README.md` for how they're structured.
