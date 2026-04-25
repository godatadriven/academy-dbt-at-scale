# Group 4 - Power Users: Production Hardening

## Your mission

You're the platform team. The other groups are building features; you're making sure the whole MediaPulse project is ready to run in production. That means auditing quality, enforcing standards, hardening tests, and designing a CI/CD pipeline that catches problems before they reach the warehouse.

This is a **2-day open hackathon**. There is no prescribed order beyond the checklist steps - prioritise based on what you find.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Run **dbt-project-evaluator** and interpret its output to identify structural problems
- Use **dbt-codegen** to auto-generate YAML for undocumented sources and models
- Apply **dbt-expectations** for statistical and distributional data quality tests
- Define **model contracts** to enforce column-level schemas at run time
- Reason about **test severity** (`error` vs `warn`) and when each is appropriate
- Design a **CI/CD pipeline** using dbt Cloud jobs: slim CI, nightly full-refresh, PR validation
- Articulate the difference between **hard requirements** (must pass before deploy) and **nice-to-haves**

---

## Key tools

### dbt-project-evaluator

Installs as a dbt package. Runs a suite of models that query your project's metadata and flags structural violations (missing documentation, fan-out tests, exposure gaps, etc.).

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=0.8.0", "<1.0.0"]
```

```bash
dbt deps
dbt build --select package:dbt_project_evaluator
```

Results land in models prefixed `fct_` and `rpt_` - query them to see violations.

### dbt-codegen

Generates boilerplate YAML so you don't have to write it by hand.

```bash
# Generate a source definition
dbt run-operation generate_source --args '{"schema_name": "streaming"}'

# Generate model YAML (columns + descriptions stub)
dbt run-operation generate_model_yaml --args '{"model_names": ["stg_streaming__watch_events"]}'
```

Paste the output into your YAML files and fill in descriptions.

### dbt-expectations

A port of Great Expectations into dbt. Adds dozens of statistical tests beyond the four built-in generics.

```yaml
models:
  - name: fct_ad_impressions
    tests:
      - dbt_expectations.expect_table_row_count_to_be_between:
          min_value: 1000
          max_value: 50000000
    columns:
      - name: impressions_count
        tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 10000000
```

### Model contracts

Contracts enforce that a model's schema matches its YAML definition at run time. If a column is missing or has the wrong type, the run fails.

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
```

---

## CI/CD in dbt Cloud

The goal is to catch problems as early as possible:

| Job | Trigger | Selector | Purpose |
|-----|---------|----------|---------|
| **Slim CI** | PR opened / updated | `state:modified+` | Only rebuild what changed and its downstream |
| **Nightly full-refresh** | Cron 02:00 | `+` (all) | Full rebuild, catch schema drift |
| **PR validation** | PR merge | `tag:critical` | Run critical-path models + tests before merge |

The slim CI job requires a **deferred environment** - it compares your changed models against the production manifest (`manifest.json`) so it knows what "state:modified" means.

---

## Time guide

This is intentionally open-ended. A suggested arc:

| Session | Focus |
|---------|-------|
| Day 1 AM | Audit with dbt-project-evaluator; triage findings |
| Day 1 PM | Fix highest-priority violations; add dbt-codegen YAML |
| Day 2 AM | dbt-expectations; model contracts; test severity review |
| Day 2 PM | CI/CD design; hard requirements document; prep presentation |

Head to the [Checklist](checklist.md) when you're ready to start.
