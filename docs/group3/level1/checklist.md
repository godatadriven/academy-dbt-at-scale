# Group 3 - Checklist Level 1

## Project Audit and Package Tests

Start here. Your first job is to understand the state of both projects before improving them.

In this level you will:

- **Run dbt-project-evaluator** on `mediapulse_platform` and triage findings
- **Fix** the highest-priority violations
- **Install and apply** elementary package tests for anomaly detection

Work through the steps in order. Document your decisions as you go.

---

## Step 1 - Install packages

- [ ] Step complete

Add the following packages to `mediapulse_platform/packages.yml`:

- `dbt-labs/dbt_project_evaluator` (check [hub.getdbt.com](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the current version)
- `dbt-labs/codegen` (for documentation generation later)
- `elementary-data/elementary` (for anomaly detection tests)

Then run `dbt deps` to install them.

Read the [dbt-project-evaluator documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/) and the [elementary package documentation](https://docs.elementary-data.com/data-tests/dbt/dbt-package) before proceeding.

??? tip "Hint: version conflicts"
    Run `dbt --version` to check what dbt version is installed. If a package requires a newer version, your facilitator can update the project's `require-dbt-version` or suggest a compatible package version.

---

## Step 2 - Run dbt-project-evaluator

- [ ] Step complete

```bash
dbt build --select package:dbt_project_evaluator
```

Then query the results tables:

```sql
select * from dbt_project_evaluator.fct_missing_primary_key_tests;
select * from dbt_project_evaluator.fct_undocumented_models;
select * from dbt_project_evaluator.fct_direct_join_to_source;
select * from dbt_project_evaluator.fct_model_naming_conventions;
```

For each finding, classify it as: **Must fix**, **Should fix**, or **Will not fix by design**. Record your reasoning. You will present these findings.

The full list of evaluator models is in the [documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/).

??? tip "Hint: what usually matters most"
    1. Missing `unique` and `not_null` tests on primary keys (silent duplicates propagate)
    2. Marts or intermediate models that join directly to raw sources (no lineage, no quality gate)
    3. Models with no descriptions (onboarding and debugging pain)

    Naming convention violations are important for consistency but rarely cause production incidents.

---

## Step 3 - Triage and prioritise

- [ ] Step complete

For each violation, write a short rationale:

- Must fix before production: data correctness risk, missing key tests, direct source references in marts
- Should fix: documentation gaps, naming convention violations
- Will not fix: architectural decisions made consciously

Share your triage with your group before moving on. Disagreements about what is a "must fix" are worth discussing.

---

## Step 4 - Fix the highest-priority violations

- [ ] Step complete

Work through your **Must fix** list. Common fixes:

- Add missing `not_null` and `unique` tests to YAML files
- Add descriptions to models and columns
- Refactor any mart models that join directly to raw sources to go through staging

After each fix, re-run the evaluator to confirm the violation count drops:

```bash
dbt build --select package:dbt_project_evaluator
```

---

## Step 5 - Use codegen to fill documentation gaps

- [ ] Step complete

For any staging models that lack YAML documentation, use codegen to generate a starter:

```bash
dbt run-operation generate_model_yaml \
  --args '{"model_names": ["stg_ads__campaigns"]}'
```

Paste the output into the appropriate YAML file and fill in the descriptions. The column list comes from codegen; the meaning of each column comes from you.

---

## Step 6 - Install elementary's internal models

- [ ] Step complete

Before applying elementary tests, its internal models need to exist in your schema:

```bash
dbt run --select elementary
```

This creates the tables elementary uses to store its run history and anomaly baselines. You only need to do this once per environment.

---

## Step 7 - Apply elementary anomaly tests

- [ ] Step complete

Add elementary anomaly detection tests to at least two models. Good candidates are high-volume tables where silent row-count drops or null-rate spikes would be hard to notice without automated checks.

Read the [elementary package documentation](https://docs.elementary-data.com/data-tests/dbt/dbt-package) to find the available test types and their configuration options.

Key tests to consider:

| Test | What it detects |
|------|-----------------|
| `elementary.volume_anomalies` | Row count spikes or drops vs. historical baseline |
| `elementary.freshness_anomalies` | Data arriving later than usual |
| `elementary.null_count_anomalies` | Null rate changes in a column |

After applying the tests, run them:

```bash
dbt test --select stg_news__articles
```

When would these tests fire in a real production pipeline? What would cause a volume anomaly on the articles table?

---

## Step 8 - BONUS: Run the full build and review

- [ ] Step complete

```bash
dbt build --select staging.news staging.podcasts staging.ads
```

Fix any remaining failures. Confirm the evaluator violation count is at its lowest before moving on to Level 2.

---

!!! success "Done?"
    You have audited both projects, triaged findings by risk, fixed the most dangerous issues, and added anomaly detection to key models.

    Head to [Level 2](../level2/checklist.md) to add model contracts, access controls, and cross-project references!
