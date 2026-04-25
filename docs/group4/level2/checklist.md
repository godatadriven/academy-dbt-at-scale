# Group 4 - Checklist Level 2

## dbt Level Up: Hardening for Production

Start on this checklist once you have completed [Checklist Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **dbt-expectations** — statistical guardrails on critical models
- **Model contracts** — schema enforcement at compile time
- **Test severity** — `warn` vs `error` decisions
- **CI/CD design** — slim CI, nightly refresh, production deploy
- **Hard requirements** — what must pass before any production deploy

Work through the steps in order. Document decisions as you go — you'll present findings at 16:00 on Day 2.

---

## Step 1 - Apply dbt-expectations to critical models

- [ ] Step complete

Add statistical tests to the most important mart models. Focus on:

- Row count bounds (catch silent truncations)
- Column value bounds (catch sign errors, unit errors)
- Column completeness (null rate below threshold)

??? tip "Hint: dbt-expectations on `fct_ad_impressions`"
    ```yaml
    models:
      - name: fct_ad_impressions
        data_tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              min_value: 1000           # fail if the table is suspiciously small
              max_value: 100000000      # fail if it explodes (fan-out bug)
        columns:
          - name: impressions_count
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0
                  max_value: 10000000
              - dbt_expectations.expect_column_values_to_not_be_null:
                  mostly: 1.0           # 100% non-null required
          - name: click_through_rate
            data_tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0.0
                  max_value: 1.0        # CTR can't exceed 100%
    ```

??? tip "Hint: dbt-expectations on `content_performance`"
    ```yaml
    models:
      - name: content_performance
        data_tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              min_value: 500
        columns:
          - name: platform
            data_tests:
              - dbt_expectations.expect_column_distinct_values_to_equal_set:
                  value_set: ['news', 'podcasts']
    ```

---

## Step 2 - Define model contracts on critical marts

- [ ] Step complete

Add `contract: {enforced: true}` to `content_performance` and `revenue_by_content`. This means dbt will verify the model's output schema matches the YAML definition at compile time.

??? tip "Hint: Contract config"
    ```yaml
    models:
      - name: revenue_by_content
        config:
          contract:
            enforced: true
        columns:
          - name: content_id
            data_type: varchar
            constraints:
              - type: not_null
          - name: impression_date
            data_type: date
            constraints:
              - type: not_null
          - name: mediapulse_revenue_dollars
            data_type: float
    ```

    If the model produces a column with a different type or name, the run fails with a clear error — this catches schema drift before it reaches consumers.

    !!! warning
        Contracts require that **all** columns in the model are listed in YAML. Missing columns cause a compile error. Use dbt-codegen (Level 1 Step 5) to get the full column list first.

---

## Step 3 - Review test severity across the project

- [ ] Step complete

Go through all model YAML files and consider which tests should be `warn` vs `error`:

| Severity | Use when |
|----------|----------|
| `error` | Failure means data is corrupt or a key business invariant is violated |
| `warn` | Failure is unexpected but not immediately harmful; needs investigation |

??? tip "Hint: Setting severity"
    ```yaml
    columns:
      - name: mediapulse_revenue_dollars
        data_tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 1000000
              config:
                severity: warn    # revenue exceeding $1M/row is suspicious but not a hard stop
    ```

    Good candidates for `warn` severity:
    - Row count bounds (catch trends, not hard failures)
    - Freshness checks beyond a certain threshold
    - `accepted_values` tests on categories that might legitimately grow

    Hard `error`:
    - `not_null` on primary keys
    - `unique` on primary keys
    - `relationships` tests (broken FK = broken joins)
    - Revenue assertions (money must be right)

---

## Step 4 - Design the CI/CD pipeline

- [ ] Step complete

Design a dbt Cloud job structure for MediaPulse. You need at minimum three jobs:

1. **Slim CI** — triggered on PR open/update; runs only changed models and their downstream
2. **Nightly full-refresh** — runs at 02:00; full `--full-refresh` to catch schema drift
3. **Production deploy** — triggered on merge to main; runs `+state:modified+` against production environment

For each job, define:

- Trigger (PR event, cron, API)
- dbt command and selector
- Environment (CI vs prod)
- Whether it uses a deferred environment

??? tip "Hint: Slim CI configuration"
    The slim CI job uses `state:modified+` to only run what changed:

    ```bash
    # In dbt Cloud job commands:
    dbt build --select state:modified+ --defer --state ./logs/prod-artifacts
    ```

    The `--defer` flag tells dbt to use production-compiled models for any upstream models that weren't selected. The `--state` flag points to a folder containing the production `manifest.json`.

    In dbt Cloud, you set the **Deferral environment** in the job config and don't need to handle `--state` manually.

??? tip "Hint: Nightly job"
    ```bash
    dbt build --full-refresh
    ```

    Schedule at 02:00 UTC. Send alerts to a Slack channel on failure. This job should also run `dbt source freshness` to catch upstream data delivery issues.

---

## Step 5 - Define hard requirements vs nice-to-haves

- [ ] Step complete

As a group, write a short document (a markdown file in the repo under `docs/production_requirements.md`) that answers:

**Hard requirements — must pass before any production deploy:**

- [ ] All `not_null` + `unique` tests on primary keys pass
- [ ] All `relationships` tests pass
- [ ] No model contract violations
- [ ] `content_performance` and `revenue_by_content` row counts within expected bounds
- [ ] Singular revenue assertion tests pass
- [ ] dbt-project-evaluator: zero `must_fix` violations remain

**Nice-to-haves — target within next sprint:**

- [ ] 100% of models have descriptions
- [ ] All source columns have tests
- [ ] dbt-expectations tests on all fact tables
- [ ] `warn`-severity tests for statistical bounds on dimension tables

??? tip "Hint: Framing for your presentation"
    The distinction between hard requirements and nice-to-haves is a conversation about risk tolerance. A good way to frame it:

    - Hard requirements = failures here mean "someone is making a wrong decision based on this data today"
    - Nice-to-haves = failures here mean "we might catch a problem tomorrow instead of today"

    Be prepared to justify each item in your list. Not everything needs to be a blocker.

---

## Step 6 - BONUS: Evaluate dbt-project-evaluator coverage gaps

- [ ] Step complete

dbt-project-evaluator is configurable — you can disable checks that don't apply to your project or add custom rules. Review the [evaluator documentation](https://dbt-labs.github.io/dbt-project-evaluator/) and:

1. Identify any default rules that don't make sense for MediaPulse
2. Disable them in `dbt_project.yml` using the evaluator's `vars` config
3. Consider whether any project-specific rules are missing (e.g., "all marts must have an exposure defined")

??? tip "Hint: Disabling a rule"
    ```yaml
    # dbt_project.yml
    vars:
      dbt_project_evaluator:
        # Disable the check for models that don't follow naming conventions
        # because our legacy models use a different system
        enforce_model_name_convention: false
    ```

---

## Step 7 - Prepare your presentation

- [ ] Step complete

At 16:00 Day 2 you have 10–15 minutes to present. Structure:

1. **What we found** — top 5 evaluator violations by risk level
2. **What we fixed** — concrete before/after
3. **What we added** — dbt-expectations tests, contracts, severity review
4. **CI/CD design** — diagram of your three jobs and what each catches
5. **Hard requirements** — your final list with rationale
6. **What we'd do next** — honest backlog

---

!!! success "Done?"
    You've audited, hardened, and documented the MediaPulse platform to production-ready standards. The other groups built features; you built the safety net. Neither is more important — the platform needs both.

