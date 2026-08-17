# Group 3 - Advanced II

## Your slice of MediaPulse

This is the deepest track in the workshop. You're assumed comfortable with generic and singular testing and the shape of a dbt Mesh setup already - today is about auditing coverage systematically across both projects, closing real governance gaps between what a model's documentation promises and what its configuration actually allows, designing CI/CD and unit tests for business logic that genuinely matters, and confronting the operational edges of a two-project setup that access levels alone don't solve.

---

## What gets covered

### Part 1

1. [dbt Catalog & review](1.1-dbt-catalog-and-review.md) - a fast checkpoint, then straight into using Catalog's project recommendations across both projects to prioritise real coverage gaps
2. [Testing coverage](1.2-testing-coverage.md) - a systematic audit of the newer `mediapulse_analytics` domains, and the limits of `relationships` tests across a project boundary
3. [Deployment & CI/CD](1.3-deployment-and-cicd.md) - design a pipeline for a producer/consumer project pair
4. [dbt Mesh](1.4-dbt-mesh.md) - the mesh boundary from the producer project's side

### Part 2

1. [dbt Mesh review](2.1-dbt-mesh-review.md) - find and fix a real mismatch between a model's documented intent and its actual access configuration, then design a genuinely new cross-project model end to end
2. [Advanced Testing](2.2-advanced-testing.md) - the most advanced testing content in the workshop: cross-column consistency checks and how tests interact with model contracts
3. [Dynamic data masking](2.3-dynamic-data-masking.md) - masking a column that's already crossing the mesh boundary, and the governance gap access levels alone don't close
4. [Unit testing](2.4-unit-testing.md) - dbt's native unit-testing framework, applied to real conditional business logic, and where mesh boundaries limit what you can unit test

Each topic has an **Exercise** (apply the skill directly) and an **Extension** (apply it at a noticeably higher level of difficulty) - do the Extension if you finish the Exercise with time to spare.

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

- `mediapulse_platform` - specifically `dim_campaigns` (check its documentation against its actual access config) and the intermediate models' conditional business logic
- `mediapulse_analytics` - specifically the `crm` and `streamview_legacy` domains (fully self-contained, no mesh dependency) versus `fct_content_performance`/`fct_ad_revenue` (mesh-consuming)

See the [MediaPulse overview](../mediapulse/overview.md) for the underlying business context, and each project's own `README.md` for how they're structured.
