# Group 4 — Checklist

This is a two-day open hackathon. The checklist provides a sequence but you should re-prioritise based on what the audit reveals. Document decisions as you go — you'll present findings at 16:00 on Day 2.

---

## Step 1 — Add packages and run `dbt deps`

Add the three packages to `packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=0.8.0", "<1.0.0"]
  - package: dbt-labs/dbt_codegen
    version: [">=0.12.0", "<1.0.0"]
  - package: calogica/dbt_expectations
    version: [">=0.10.0", "<1.0.0"]
```

```bash
dbt deps
```

??? tip "Hint: If you get version conflicts"
    Check `dbt_project.yml` for `require-dbt-version`. If it's pinned to an old version, some packages may not install. You may need to update the dbt version requirement or pin package versions lower. Run `dbt --version` to check what's installed.

---

## Step 2 — Run dbt-project-evaluator

```bash
dbt build --select package:dbt_project_evaluator
```

This runs a set of models that analyse your project metadata. Query the results tables:

```sql
-- Which models have no tests?
select * from dbt_project_evaluator.fct_missing_primary_key_tests;

-- Which models have no descriptions?
select * from dbt_project_evaluator.fct_undocumented_models;

-- Which source columns are untested?
select * from dbt_project_evaluator.fct_missing_source_tests;

-- Are there any direct source references in marts? (should go through staging)
select * from dbt_project_evaluator.fct_direct_join_to_source;
```

??? tip "Hint: Navigating evaluator output"
    The full list of evaluator models is in [the dbt-project-evaluator docs](https://dbt-labs.github.io/dbt-project-evaluator/). Key models to check first:

    | Model | What it flags |
    |-------|--------------|
    | `fct_missing_primary_key_tests` | Models with no `unique` + `not_null` test combo on a key column |
    | `fct_undocumented_models` | Models with no description |
    | `fct_direct_join_to_source` | Marts that join directly to raw sources, bypassing staging |
    | `fct_model_naming_conventions` | Models that don't follow `stg_`, `int_`, `fct_`, `dim_` conventions |
    | `fct_missing_source_tests` | Source columns with no tests at all |

    Create a simple tracker (a shared doc or whiteboard) categorising findings as: **Must fix**, **Should fix**, **Won't fix / by design**.

---

## Step 3 — Triage and prioritise findings

For each evaluator violation, decide:

- **Must fix before prod**: data correctness risk, missing tests on key columns, direct source references in marts
- **Should fix**: documentation gaps, naming convention violations
- **Won't fix / acceptable**: architectural decisions made consciously (e.g., a mart that intentionally queries a source for performance)

Record your triage decisions with a brief rationale — you'll present this.

??? tip "Hint: What usually matters most"
    In practice, the highest-risk findings are:

    1. Missing `unique` + `not_null` tests on primary keys (silent duplicates)
    2. Marts joining directly to raw sources (no lineage visibility, no staging quality gate)
    3. Models with zero documentation (onboarding and debugging pain)

    Naming conventions are important for consistency but rarely cause production incidents on their own.

---

## Step 4 — Fix the highest-priority violations

Work through your **Must fix** list. Typical fixes:

- Add missing primary key tests to YAML files
- Add descriptions to models and columns
- Refactor any direct-source-to-mart joins to go through staging models

```bash
dbt build --select package:dbt_project_evaluator
# Re-run after fixes to confirm violation count drops
```

---

## Step 5 — Use dbt-codegen to fill documentation gaps

For any models that lack YAML documentation, use codegen to generate a starter:

```bash
# Generate source YAML (useful if Group 1 or 3 left sources undocumented)
dbt run-operation generate_source \
  --args '{"schema_name": "raw_streaming", "database_name": "your_db"}'

# Generate model YAML for a single model
dbt run-operation generate_model_yaml \
  --args '{"model_names": ["stg_streaming__watch_events"]}'

# Generate model YAML for all models in a folder
dbt run-operation generate_model_yaml \
  --args '{"model_names": ["stg_ads__campaigns", "stg_ads__spend", "stg_ads__impressions"]}'
```

Paste the output into the appropriate YAML files, then fill in the descriptions. Codegen gives you the column list; you provide the meaning.

??? tip "Hint: What codegen output looks like"
    ```yaml
    version: 2

    models:
      - name: stg_streaming__watch_events
        description: ""         # <-- fill this in
        columns:
          - name: watch_event_sk
            description: ""     # <-- fill these in
          - name: event_id
            description: ""
          - name: user_id
            description: ""
          # ... etc
    ```

    The column list is derived from the model's compiled SQL, so it's always up to date.

---

## Step 6 — Apply dbt-expectations to critical models

Add statistical tests to the most important mart models. Focus on:

- Row count bounds (catch silent truncations)
- Column value bounds (catch sign errors, unit errors)
- Column completeness (null rate below threshold)

??? tip "Hint: dbt-expectations on `fct_ad_impressions`"
    ```yaml
    models:
      - name: fct_ad_impressions
        tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              min_value: 1000           # fail if the table is suspiciously small
              max_value: 100000000      # fail if it explodes (fan-out bug)
        columns:
          - name: impressions_count
            tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0
                  max_value: 10000000
              - dbt_expectations.expect_column_values_to_not_be_null:
                  mostly: 1.0           # 100% non-null required
          - name: click_through_rate
            tests:
              - dbt_expectations.expect_column_values_to_be_between:
                  min_value: 0.0
                  max_value: 1.0        # CTR can't exceed 100%
    ```

??? tip "Hint: dbt-expectations on `content_performance`"
    ```yaml
    models:
      - name: content_performance
        tests:
          - dbt_expectations.expect_table_row_count_to_be_between:
              min_value: 500
        columns:
          - name: platform
            tests:
              - dbt_expectations.expect_column_distinct_values_to_equal_set:
                  value_set: ['news', 'podcasts']
    ```

---

## Step 7 — Define model contracts on critical marts

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
        Contracts require that **all** columns in the model are listed in YAML. Missing columns cause a compile error. Use dbt-codegen (Step 5) to get the full column list first.

---

## Step 8 — Review test severity across the project

Go through all model YAML files and consider which tests should be `warn` vs `error`:

| Severity | Use when |
|----------|----------|
| `error` | Failure means data is corrupt or a key business invariant is violated |
| `warn` | Failure is unexpected but not immediately harmful; needs investigation |

??? tip "Hint: Setting severity"
    ```yaml
    columns:
      - name: mediapulse_revenue_dollars
        tests:
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

## Step 9 — Design the CI/CD pipeline

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

## Step 10 — Define hard requirements vs nice-to-haves

As a group, write a short document (can be a markdown file in the repo under `docs/production_requirements.md`) that answers:

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

## Step 11 — BONUS: Evaluate `dbt-project-evaluator` coverage gaps

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

## Step 12 — Prepare your presentation

At 16:00 Day 2 you have 10–15 minutes to present. Structure:

1. **What we found** — top 5 evaluator violations by risk level
2. **What we fixed** — concrete before/after
3. **What we added** — dbt-expectations tests, contracts, severity review
4. **CI/CD design** — diagram of your three jobs and what each catches
5. **Hard requirements** — your final list with rationale
6. **What we'd do next** — honest backlog

!!! success "Done?"
    You've audited, hardened, and documented the MediaPulse platform to production-ready standards. The other groups built features; you built the safety net. Neither is more important — the platform needs both.
