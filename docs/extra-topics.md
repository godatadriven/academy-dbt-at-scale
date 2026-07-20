# Extra Topics

These are optional bonus exercises for Groups 3 and 4. Pick them up if you have completed your checklist levels or want to explore a specific area in more depth.

---

## dbt Semantic Layer

The dbt Semantic Layer lets you define metrics once in dbt, in YAML, and query them consistently from any downstream tool: BI tools, notebooks, the CLI, or the dbt API. Metrics are no longer duplicated across dashboards; they are defined in code, versioned, and tested like models.

MetricFlow is the query engine underneath. It takes a metric definition and generates the correct SQL at query time, joining semantic models as needed.

**Start here:**

- [dbt Semantic Layer overview](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl)
- [Semantic models reference](https://docs.getdbt.com/docs/build/semantic-models)
- [MetricFlow CLI commands](https://docs.getdbt.com/docs/build/metricflow-commands)

**Your task:**

1. Define a semantic model over `fct_ad_revenue` or `fct_content_performance`. Identify the entities (join keys), dimensions (sliceable attributes), and measures (aggregatable values).

2. Define at least two metrics for MediaPulse. Ideas:

   | Metric | Description |
   |--------|-------------|
   | Revenue per mille (RPM) | `mediapulse_revenue_dollars / impressions_count * 1000` |
   | Click-through rate | `sum(clicks) / sum(impressions_count)` |
   | Listen completion rate | Average of `listen_duration / episode_duration_seconds` |

3. Query your metrics using the MetricFlow CLI:

   ```bash
   dbt sl list metrics
   dbt sl query --metrics rpm --group-by impression_date
   ```

**Discuss with your group:**

- If RPM is defined in the Semantic Layer, what happens when a BI developer calculates it differently in a dashboard? How does the Semantic Layer solve (or not solve) that?
- The Semantic Layer requires dbt Cloud Team or Enterprise. How would you handle metric governance if you are on dbt Core only?
- How do you test that a metric definition is correct? You cannot use `dbt test` directly on metrics.

---

## dbt Wizard

dbt Wizard is an AI-assisted authoring tool built into dbt Cloud and the Studio IDE. It can generate and refactor dbt models, write YAML documentation, suggest tests, and explain error messages, all within the dbt Cloud environment.

**Start here:**

- [dbt Wizard overview](https://docs.getdbt.com/docs/platform/wizard-overview)
- For dbt Wizard in the Studio IDE: [dbt Wizard in the dbt platform](https://docs.getdbt.com/docs/platform/wizard-platform)

**Your task:**

1. Open a model in dbt Cloud Studio and use Wizard to:
   - Generate a description for the model and its columns
   - Suggest tests for the primary key and any foreign keys
   - Explain an error message you encountered during the workshop

2. Try asking Wizard to refactor a staging model to apply your `clean_string` macro to all string columns. Review the output: does it correctly identify which columns should be normalised?

3. Compare the output to what you would have written manually. Where was Wizard useful? Where did it miss something or require correction?

**Discuss with your group:**

- How does AI-assisted authoring change the role of an analytics engineer?
- What kinds of dbt tasks are good candidates for Wizard? Where would you still prefer to write by hand?
- How would you govern AI-generated YAML in a project with model contracts?
