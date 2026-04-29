# Group 4 - Checklist Level 1

## dbt Project Audit

This is an audit-first track. Your job is to find what's broken or missing in the MediaPulse project - then fix it. The other groups built features; you build the safety net.

In this level you will:

- **Install audit packages** - `dbt-project-evaluator`, `dbt-codegen` and `elementary`
- **Run the evaluator** and surface violations
- **Triage findings** by risk level
- **Fix the highest-priority violations**
- **Fill documentation gaps** with codegen

Work through the steps in order. Document your decisions as you go - you'll present findings at 16:00 on Day 2.

---

## Step 1 - Add packages and run `dbt deps`

- [ ] Step complete

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

## Step 2 - Run dbt-project-evaluator

- [ ] Step complete

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

## Step 3 - Triage and prioritise findings

- [ ] Step complete

For each evaluator violation, decide:

- **Must fix before prod**: data correctness risk, missing tests on key columns, direct source references in marts
- **Should fix**: documentation gaps, naming convention violations
- **Won't fix / acceptable**: architectural decisions made consciously (e.g., a mart that intentionally queries a source for performance)

Record your triage decisions with a brief rationale.

??? tip "Hint: What usually matters most"
    In practice, the highest-risk findings are:

    1. Missing `unique` + `not_null` tests on primary keys (silent duplicates)
    2. Marts joining directly to raw sources (no lineage visibility, no staging quality gate)
    3. Models with zero documentation (onboarding and debugging pain)

    Naming conventions are important for consistency but rarely cause production incidents on their own.

---

## Step 4 - Fix the highest-priority violations

- [ ] Step complete

Work through your **Must fix** list. Typical fixes:

- Add missing primary key tests to YAML files
- Add descriptions to models and columns
- Refactor any direct-source-to-mart joins to go through staging models

```bash
dbt build --select package:dbt_project_evaluator
# Re-run after fixes to confirm violation count drops
```

---

## Step 5 - Use dbt-codegen to fill documentation gaps

- [ ] Step complete

For any models that lack YAML documentation, use codegen to generate a starter:

```bash
# Generate source YAML (useful if other groups left sources undocumented)
dbt run-operation generate_source \
  --args '{"schema_name": "streaming", "database_name": "your_db"}'

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

## Step 6 - elementary

[Elementary](https://docs.elementary-data.com/data-tests/dbt/dbt-package) is an open-source dbt package for data observability: anomaly detection tests, a run history dashboard, and alerting — without leaving dbt.

Your goal is to install this package, run its models and apply some of its tests.

Elementary ships as a dbt package. Its models run inside the dbt project and write results to an `elementary` schema. A separate CLI tool (`edr`) reads those results to generate reports and send alerts.

```yaml
# packages.yml
packages:
  - package: elementary-data/elementary
    version: [">=0.13.0", "<0.14.0"]
```

??? question "How can you run elementary?"

    ```bash
    dbt run --select elementary      # build Elementary's internal audit models
    edr report                       # generate local HTML report
    edr send-report                  # send to Slack / email
    ```

??? question "What are some key tests to run?"
    Key anomaly tests

    | Test | What it detects |
    |---|---|
    | `elementary.volume_anomalies` | Row count spikes or drops vs. historical baseline |
    | `elementary.freshness_anomalies` | Data arriving later than usual |
    | `elementary.null_count_anomalies` | Null rate changes in a column |
    | `elementary.all_columns_anomalies` | Runs multiple checks across all columns automatically |

    ```yaml
    models:
      - name: stg_news__articles
        data_tests:
          - elementary.volume_anomalies:
              timestamp_column: published_at
          - elementary.freshness_anomalies:
              timestamp_column: updated_at
    ```


---

!!! success "Done?"
    You've installed the audit toolchain, surfaced violations, triaged them by risk, and fixed the highest-priority issues. The project is materially safer than when you started.

    Now head to [Level 2](../level2/checklist.md) to add statistical guardrails, model contracts and design the CI/CD pipeline!

