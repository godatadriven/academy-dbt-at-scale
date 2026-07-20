# Group 3 - Checklist Level 3

## CI/CD Pipelines for a Multi-project Setup

Start on this checklist once you have completed [Level 2](../level2/checklist.md).

In this level you will:

- **Design and set up dbt Cloud CI/CD jobs** for both the platform and analytics projects
- **Think through the ordering and dependency implications** of a two-project pipeline
- **Document hard requirements** for production deployment

Read the [dbt Cloud CI jobs documentation](https://docs.getdbt.com/docs/deploy/ci-jobs) before starting.

---

## Step 1 - Design the job structure for both projects

- [ ] Step complete

Before clicking anything in dbt Cloud, design the job structure on paper (or a shared whiteboard). For each project, you need:

1. A **slim CI job** triggered on PR open or update: rebuilds only changed models and their downstream
2. A **nightly full-refresh job** to catch schema drift
3. A **production deploy job** triggered on merge to main

For a two-project setup, also answer:

- If a change to `mediapulse_platform` breaks a model in `mediapulse_analytics`, which CI job catches that?
- Should the platform's production deploy trigger the analytics project's production deploy? How?
- What should happen if the platform nightly fails? Should the analytics nightly still run?

There is no single right answer. Document your choices and be ready to defend them.

---

## Step 2 - Set up the platform slim CI job

- [ ] Step complete

In dbt Cloud, create a CI job for `mediapulse_platform` with:

- Trigger: PR events (open and update)
- Command: `dbt build --select state:modified+`
- Deferred environment: production (so dbt knows what "modified" means relative to)

Read the [CI jobs documentation](https://docs.getdbt.com/docs/deploy/ci-jobs) for how to configure a deferred environment and the `state:modified+` selector.

??? tip "Hint: what slim CI actually does"
    The `state:modified+` selector compares your current code to the production manifest. Only models that have changed code (or depend on a changed model) are rebuilt. This makes CI fast: a one-line fix to `stg_news__articles` does not rebuild the entire project.

    The `--defer` flag tells dbt to use production-compiled models for any upstream dependencies that were not selected. This avoids rebuilding the whole upstream graph just to test one model.

---

## Step 3 - Set up the analytics slim CI job

- [ ] Step complete

Create a CI job for `mediapulse_analytics` with the same structure. Note:

- The analytics project depends on the platform project. If the platform contracts change, the analytics CI should catch the breakage.
- Consider adding a step that first builds the platform project (or validates that the platform production manifest is current) before running the analytics CI.

---

## Step 4 - Set up nightly full-refresh jobs

- [ ] Step complete

Create nightly jobs for both projects, scheduled at 02:00:

- Platform job: `dbt build --full-refresh` then `dbt source freshness`
- Analytics job: `dbt build --full-refresh` (runs after platform completes if possible)

Add failure alerting: dbt Cloud can send notifications to Slack or email when a job fails. Configure at least one notification channel.

---

## Step 5 - Define hard requirements for production

- [ ] Step complete

As a group, write a short document listing what must pass before any merge to main in either project:

**Platform hard requirements:**
- All `not_null` and `unique` tests on primary keys
- All model contracts enforced without errors
- Zero `must_fix` violations in dbt-project-evaluator

**Analytics hard requirements:**
- Cross-project refs resolve without errors
- Revenue singular tests pass (`assert_revenue_not_null`, `assert_no_negative_spend`)
- Row counts on key mart models are within expected bounds

Document what is a "nice to have" vs a "must have" and be ready to defend the distinction.

---

## Step 6 - BONUS: See the extra topics

- [ ] Step complete

See the [Extra Topics](../extra-topics.md) page for the dbt Semantic Layer and dbt Wizard exercises. Pick these up if you have time.

---

!!! success "Done?"
    You have designed and set up a production-grade CI/CD pipeline for a two-project dbt mesh, defined hard requirements for production deployment, and thought through the cross-project dependency implications of the pipeline.
