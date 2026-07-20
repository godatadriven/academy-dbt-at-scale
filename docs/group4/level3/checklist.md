# Group 4 - Checklist Level 3

## Bonus Level and Further Topics

Start on this checklist once you have completed [Level 2](../level2/checklist.md).

This level is intentionally open-ended. Your facilitator will agree the focus areas with your group based on what you have completed and what interests you most.

---

## Option A - CI/CD for a multi-project setup

Design and set up dbt Cloud CI/CD jobs for both `mediapulse_platform` and `mediapulse_analytics`.

Key questions to address:

- How does slim CI work differently when one project depends on another?
- Which project's CI job should run first when a PR touches both?
- If the platform contract changes, how does the analytics CI catch the breakage?

Read the [dbt Cloud CI jobs documentation](https://docs.getdbt.com/docs/deploy/ci-jobs) and design a job structure that accounts for the cross-project dependency. Set up at least one slim CI job and one nightly full-refresh job in dbt Cloud.

---

## Option B - Deeper governance: model versions

Public models in `mediapulse_platform` form a contract with `mediapulse_analytics`. When you need to make a breaking change (rename a column, change a type), you need to introduce a new model version so downstream consumers can migrate on their own schedule.

Explore model versioning using the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access):

1. Create a v2 of one of your contracted staging models with a deliberate breaking change (e.g. rename a column).
2. Update the analytics project to pin to v1 while you plan a migration to v2.
3. Migrate the analytics project to v2, then deprecate v1.

When should you use versioning vs. just making the change and updating all refs? Discuss the trade-offs with your group.

---

## Option C - Extra topics: Semantic Layer and dbt Wizard

See the [Extra Topics](../extra-topics.md) page for guided exercises on the dbt Semantic Layer and dbt Wizard. These are the newest product areas and the least familiar to most teams, so they are excellent for an advanced group.

---

## Option D - Agreed live with your facilitator

If you have ideas for topics not covered above, raise them with your facilitator. This group is the most advanced and the schedule is flexible.

---

!!! info "Further topics are agreed live"
    Your facilitator will confirm which of the above options to pursue and may introduce additional topics based on your progress and the group's interests. There is no prescribed order.
