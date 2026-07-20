# Group 2 - Checklist Level 2

## Jinja Review and Macros

Start on this checklist once you have completed [Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Jinja review**: using Jinja templating to write cleaner, more dynamic SQL
- **Macros**: writing reusable functions and a `generate_schema_name` macro for environment-based schema routing

Read the [Jinja and macros documentation](https://docs.getdbt.com/docs/build/jinja-macros) before starting.

---

## Step 1 - Review Jinja in existing models

- [ ] Step complete

Open the existing staging models and find places where Jinja is already used. Identify:

- `{{ source(...) }}` and `{{ ref(...) }}` calls
- Any `{% if ... %}` or `{% for ... %}` blocks
- Any macro calls from packages (e.g. `dbt_utils.generate_surrogate_key`)

Answer: what problem does each piece of Jinja solve compared to writing plain SQL?

---

## Step 2 - Write a `clean_string` macro

- [ ] Step complete

Several staging models apply the same pattern to normalise string columns: trim whitespace, convert to lowercase, coalesce nulls to an empty string.

Create `macros/clean_string.sql` in `mediapulse_platform`. The macro should accept a column name and return the normalised expression.

Read the [Jinja and macros documentation](https://docs.getdbt.com/docs/build/jinja-macros) for the `{% macro %}` block syntax.

After creating the macro, apply it to the following columns in the staging models you fixed in Level 1:

- `stg_news__articles`: `category`, `status`
- `stg_podcasts__episodes`: `category` (via the shows join if present)

Run the models and confirm the output is unchanged:

```bash
dbt run --select stg_news__articles stg_podcasts__episodes
dbt test --select stg_news__articles stg_podcasts__episodes
```

??? tip "Hint: how macros are called in SQL"
    After defining a macro, you call it in a model like any function:

    ```sql
    {{ clean_string('column_name') }} as column_name
    ```

    The macro receives the column name as a string and returns a SQL expression. The compiled output is the full expression, which the warehouse evaluates.

---

## Step 3 - Write a `cents_to_dollars` macro

- [ ] Step complete

Create `macros/cents_to_dollars.sql` in `mediapulse_platform`. The macro should accept a column name and return a dollar-rounded expression.

Apply it to any monetary columns in the staging models you have worked on.

---

## Step 4 - Understand `generate_schema_name`

- [ ] Step complete

The `mediapulse_platform` project already contains `macros/generate_schema_name.sql`. Open it and read it carefully.

Answer:

- What does this macro do differently from the default dbt schema naming?
- When would this macro produce a different output than the default?
- How does it ensure that dev schemas and prod schemas stay separate?

The [Jinja and macros documentation](https://docs.getdbt.com/docs/build/jinja-macros) has context on how dbt uses `generate_schema_name`.

---

## Step 5 - Extend `generate_schema_name` for a new environment

- [ ] Step complete

The current macro handles `dev` and `prod`. Extend it to also handle a `ci` target, where all schemas should be prefixed with `ci_` (e.g. `ci_staging_news`, `ci_marts`).

Test your change by looking at the compiled output for a model in the `ci` target:

```bash
dbt compile --target ci --select stg_news__articles
```

Check the compiled SQL to confirm the schema name matches your expectation.

??? tip "Hint: how to add a target condition"
    The `generate_schema_name` macro uses `target.name` to check the current target. Add an `elif target.name == 'ci'` branch with the appropriate prefix logic.

---

## Step 6 - BONUS: Refactor repetitive SQL with a Jinja for loop

- [ ] Step complete

Find a model that applies the same transformation to several columns in a row (e.g. normalising five string columns with `lower(trim(...))`). Refactor it to use a `{% for ... %}` loop over a list of column names, and call your `clean_string` macro inside the loop.

Does the refactored version produce identical compiled SQL? Run `dbt compile` to check.

---

!!! success "Done?"
    You have written two reusable macros, applied them across staging models, and extended the environment-routing macro. Your project now has less repetition and clearer SQL.

    Head to [Level 3](../level3/checklist.md) for custom generic tests!
