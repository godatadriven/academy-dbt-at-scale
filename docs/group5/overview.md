# Group 5 - Power Users

## Advanced dbt & Snowflake

This is a self-directed track. There are no levels — pick the exercises that interest you or that are most relevant to the work you do day-to-day. Each exercise is standalone; you don't need to complete them in order.

You're expected to read the linked docs, experiment, and draw your own conclusions. The facilitators won't walk you through these — they'll discuss findings with you.

---

## Exercises

| Exercise | Skills |
|---|---|
| [Snapshots](snapshots.md) | SCD Type 2, `timestamp` vs `check` strategy, hard deletes |
| [Semantic Layer](semantic_layer.md) | MetricFlow, metric definitions, `dbt sl` commands |
| [dbt Mesh](dbt_mesh.md) | Cross-project refs, model access (`public`/`protected`/`private`), model versions |
| [Snowflake Optimization](snowflake_optimization.md) | Clustering keys, micro-partitions, materialized views, microbatch incremental |
| [Python Models](python_models.md) | Snowpark, when SQL isn't enough, limitations |

---

## How to use this track

- Read the exercise page and the linked docs before writing any code
- Try to predict what will happen before you run something — then check
- Push back on the exercises: if you'd do it differently in production, say so and why
- Bring your findings to the group discussion at 16:00 on Day 2

These exercises cover features that are genuinely advanced and sometimes production-risky. Some of them are "should I even use this?" questions as much as "how do I use this?" questions.
