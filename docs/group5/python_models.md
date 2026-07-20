# Exercise: Python Models (Snowpark)

## What are Python models in dbt?

dbt supports Python models via Snowpark (on Snowflake). Instead of a `.sql` file, you write a `.py` file that returns a Snowpark DataFrame. dbt materializes it as a table or view.

📖 [dbt Python models](https://docs.getdbt.com/docs/build/python-models)
📖 [Snowpark Python developer guide](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)

---

## When does Python make sense?

SQL is declarative and well-suited to set-based transformations. Python is better when you need:

- **Statistical operations** that SQL can't express cleanly (percentile bootstrapping, rolling z-scores, distribution fitting)
- **ML inference** — calling a trained model against each row
- **Text processing** — tokenization, regex extraction, NLP features
- **Fuzzy matching** — deduplication where `=` isn't enough
- **Complex iterative logic** — anything that requires a loop or recursion

The bar for using Python over SQL should be high. Python models are slower to build, can't be materialized as views, and have no unit test support in dbt (as of 1.8).

---

## Your task

### 1. Read the structure

A dbt Python model looks like this:

```python
import snowflake.snowpark.functions as F

def model(dbt, session):
    # Reference upstream dbt models
    fct_impressions = dbt.ref("fct_ad_impressions")
    
    # Transform using Snowpark DataFrame API
    result = fct_impressions.filter(
        F.col("impressions_count") > 0
    ).with_column(
        "log_impressions",
        F.log(F.lit(10), F.col("impressions_count"))
    )
    
    return result
```

The `dbt.ref()` and `dbt.source()` functions work the same as in SQL. The function must be named `model` and must return a DataFrame.

### 2. Think about the MediaPulse use cases

Which of these would genuinely need Python vs. could be done in SQL?

| Use case | Python or SQL? |
|---|---|
| Calculate rolling 7-day average CTR per campaign | ? |
| Detect campaigns with CTR > 3 standard deviations above mean | ? |
| Extract content category from article title using a regex | ? |
| Fuzzy-match podcast episode titles across two sources to find duplicates | ? |
| Call a trained spend-forecasting model to predict next week's revenue | ? |

Be honest: SQL window functions handle rolling averages and standard deviations. Python is genuinely better for fuzzy matching and ML inference.

### 3. Write a Python model (if you have time)

Pick one use case where Python is clearly better than SQL. Write it as a dbt Python model. Keep it simple — the goal is to understand the execution environment, not to build a production ML pipeline.

Useful Snowpark functions:
- `F.col()`, `F.lit()`, `F.when()`, `F.log()`, `F.stddev()`
- `DataFrame.group_by()`, `.agg()`, `.join()`, `.filter()`
- `F.call_udf()` — call a Snowflake UDF from Python

### 4. Understand the limitations

Test these:

- Try to set `materialized='view'` in the config. What error do you get?
- Try to write a dbt unit test (`unit_tests:`) against a Python model. Does it work?
- Check the build time of a Python model vs. an equivalent SQL model — how much slower is it?

### 5. The harder question

After writing your Python model, ask: **could this have been done in SQL?**

If yes: why did Python feel tempting? Was it familiarity, or a genuine capability gap?

If no: document exactly what SQL can't express cleanly. That's your actual justification for the Python model.

---

## Discussion questions

- Given that Python models have no unit test support, how would you validate correctness?
- If you're using Python for ML inference, where should the model training live — in dbt, in a separate pipeline, or in Snowflake ML?
- What's your team's policy on Python vs. SQL in dbt? Is the decision made case-by-case, or do you have a rule?
- Snowpark runs on Snowflake's virtual warehouse. What are the cost implications of running complex Python transformations vs. pure SQL?
