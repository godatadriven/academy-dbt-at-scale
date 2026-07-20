# Exercise: Semantic Layer & MetricFlow

## What is the dbt Semantic Layer?

The Semantic Layer lets you define metrics once in dbt — in YAML — and query them consistently from any downstream tool: BI tools, notebooks, the CLI, or the dbt API. Metrics are no longer duplicated across dashboards; they're defined in code, versioned, and tested like models.

MetricFlow is the query engine underneath. It takes a metric definition and generates the correct SQL at query time, joining semantic models as needed.

📖 [Semantic Layer overview](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl)
📖 [Semantic models](https://docs.getdbt.com/docs/build/semantic-models)
📖 [Metrics reference](https://docs.getdbt.com/docs/build/metrics-overview)
📖 [MetricFlow CLI commands](https://docs.getdbt.com/docs/build/metricflow-commands)

---

## Your task

### 1. Define a semantic model

A semantic model wraps a dbt model and tells MetricFlow how to interpret it — what are the entities (join keys), dimensions (sliceable attributes), and measures (aggregatable values).

Create a semantic model over `fct_ad_impressions` (or `fct_ad_revenue`). Define:

- **Entities**: the primary and foreign keys (e.g., `campaign_id`, `content_id`)
- **Dimensions**: attributes you'd want to filter or group by (e.g., `impression_date`, `campaign_type`)
- **Measures**: values to aggregate (e.g., `impressions_count`, `allocated_spend_cents`, `click_through_rate`)

### 2. Define metrics

Create at least three metrics for MediaPulse:

| Metric idea | Description |
|---|---|
| Revenue per mille (RPM) | `mediapulse_revenue_dollars / impressions_count * 1000` |
| Click-through rate | `sum(clicks) / sum(impressions_count)` |
| Podcast listen completion rate | `avg(listen_fraction)` where `listen_fraction = listen_duration / duration_seconds` |
| Revenue by campaign type | `sum(allocated_spend_dollars)` broken down by `campaign_type` |

### 3. Query with MetricFlow

```bash
# List available metrics
dbt sl list metrics

# Query a metric
dbt sl query --metrics rpm --group-by impression_date

# Query with a dimension filter
dbt sl query --metrics click_through_rate --group-by campaign_type --where "campaign_type = 'video'"
```

### 4. Think critically

- **Single source of truth**: if RPM is defined in the Semantic Layer, what happens when a BI developer calculates it differently in a dashboard? How does the Semantic Layer solve (or not solve) this?
- **Derived metrics**: MetricFlow supports derived metrics (ratio of two measures). Where does the calculation live vs. in a mart model?
- **Availability**: the Semantic Layer requires dbt Cloud Enterprise or a self-hosted MetricFlow server. How would you use it if you're on dbt Core only?
- **Testing**: how do you test that a metric definition is correct? (Hint: you can't use `dbt test` directly on metrics — what's the alternative?)

---

## Discussion questions

- What's the difference between a metric defined in the Semantic Layer vs. a column in a mart?
- Would you migrate all your BI logic to MetricFlow? What would you keep in the mart?
- Who owns metric definitions — data engineers, analytics engineers, or business stakeholders?
