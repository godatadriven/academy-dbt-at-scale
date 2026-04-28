# Group 1 - Checklist Level 2

## dbt Level Up

Start on this checklist once you have completed [Checklist Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Further testing** - `accepted_values` and `relationships`
- **External package** - Use the `generate_surrogate_key` macro from `dbt_utils`
- **Jinja & Macros** - `clean_string` and `cents_to_dollars`
- **Singular tests** - custom SQL assertions

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Add `accepted_values` tests

- [ ] Step complete

Accordingly to internal documentation, these columns should only have the following values:
- `subscription_status` in `stg_streaming__subscriptions`
    - paused
    - cancelled
    - active
    - trialing 
- `plan_type` in `stg_streaming__subscriptions`
    - premium
    - standard
    - basic
- `device_type` in `stg_streaming__watch_events`
    - smart tv
    - tablet
    - web
    - mobile

Add three `accepted_values` tests to `_streaming__models.yml` for those columns. 

Then run the tests and observe what happens.

```bash
dbt test --select stg_streaming__subscriptions stg_streaming__watch_events
```

Expect failures. The goal right now is to understand *why* they fail - not fix them yet.


??? tip "Hint: accepted_values YAML structure"
    Use the list structure in yaml - you have two options.

    Option 1:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            arguments:
                values: ['val1', 'val2', 'val3', ...]
    ```

    Option 2:

    ```yaml
    - name: column_name
      data_tests:
        - accepted_values:
            arguments:
                - val1
                - val2
                - val3
                ...
    ```

??? question "How can you find out what values exist?"

    ```sql
    select distinct subscription_status from {{ ref('stg_streaming__subscriptions') }}
    ```

    ```sql
    select distinct plan_type from {{ ref('stg_streaming__subscriptions') }}
    ```

    ```sql
    select distinct device_type from {{ ref('stg_streaming__watch_events') }}
    ```

    You'll see values like `'Premium'` alongside `'premium'`, and `'Smart TV'` alongside `'smart tv'`. Your `accepted_values` list needs to match exactly what comes out of the staging model - so you have two choices: list *every* casing variant, or *normalise the values in the staging model*.
    
    It is up to you to decide which is the right option.


---

## Step 2 - Add a `relationships` test

- [ ] Step complete

A `relationships` test checks that every value in one column exists in another model's column - the dbt equivalent of a foreign key check.

Add a `relationships` test to `stg_streaming__watch_events` to assert that every `content_id` in watch events has a matching row in `stg_streaming__content_catalog`.

??? tip "Hint: relationships test syntax"
    In `_streaming__models.yml`, under `stg_streaming__watch_events`:

    ```yaml
    columns:
      - name: column_name
        description: Foreign key to column_name in table_name
        data_tests:
          - not_null
          - relationships:
              arguments:
                to: ref('model_name')
                field: primary_key_column_name
    ```

??? warning "Important: Do you understand the logic?"
    Find the code for the relationships test in Debug logs - does the SQL make sense? When would this test fail?
    
    What would cause that in a real system?

---

## Step 3 - Use the `dbt_utils.generate_surrogate_key()` macro

- [ ] Step complete

Replace your code that uses the `MD5` function in `stg_streaming__watch_events` so that it uses the macro from the `dbt_utils` package.

- Check that dbt_utils is in the `packages.yml` file
- Look up the [generate_surrogate_key](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/#generate_surrogate_key%20(source):~:text=generate_series(upper_bound%3D1000)%20%7D%7D-,generate_surrogate_key%20(source),-This%20macro%20implements) documentation to see how it works
- Update your code to use the `generate_surrogate_key` function from the `dbt_utils` package

??? tip "Hint: Surrogate key with dbt_utils"
    Here's the syntax for using the `generate_surrogate_key` function. Notice the need for the `{{ double curly braces }}`! 

    ```sql
    {{
        dbt_utils.generate_surrogate_key(['column_1', 'column_2', 'column_3'])
    }}   as name_of_column
    ```

---

## Step 4 - Write a `clean_string` macro

- [ ] Step complete

Create `macros/clean_string.sql`. The macro should accept a column name and return an expression that trims whitespace, converts to lowercase, and coalesces nulls to an empty string.

??? tip "Hint: Writing the macro"
    ```sql
    {% macro clean_string(column_name) %}
        coalesce(lower(trim({{ column_name }})), '')
    {% endmacro %}
    ```


---

## Step 5 - Apply `clean_string` in your staging models

- [ ] Step complete

Update the following columns in the models to use your new macro:

- `stg_streaming__content_catalog` 
    - `genre`
    - `content_type`
- `stg_streaming__watch_events` 
    - `device_type`
- `stg_streaming__subscriptions` 
    - `status` 
    - `plan_type`

```bash
dbt run --select stg_streaming__watch_events stg_streaming__subscriptions
dbt test --select stg_streaming__watch_events stg_streaming__subscriptions
```

??? tip "Hint: Calling the macro"

    Macros receive expressions, so callers pass the column name as a string:

    ```sql
    {{ clean_string('device_type') }} as device_type
    ```

??? warning "Check!"
    Do the `accepted_values` tests you wrote in Step 1 still pass?

---

## Step 6 - Write a `cents_to_dollars` macro and apply it

- [ ] Step complete

Create `macros/cents_to_dollars.sql`. The macro accepts a column name and returns a division expression.

Then update `stg_streaming__subscriptions.sql` to use it for `monthly_fee_cents`.

??? tip "Hint: Create the macro"
    The functionality you want is this:

    ```sql
    column_name / 100.0::numeric(16, 2)
    ```

??? tip "Hint: Call the macro"
    Create a macro wrapper in your new file and apply it later using:

    ```sql
    {{ cents_to_dollars('column_name') }} as new_column_name
    ```

    Verify the output looks right by running the code in `stg_streaming__subscriptions`

---

## Step 7 - Write a singular test

- [ ] Step complete

Singular tests are plain `.sql` files in the `tests/` folder. 

??? question "When does a test pass in dbt?"
    A test **passes** when the query returns **zero rows** - any rows returned are failures.
    
Write a test that asserts no watch event has a duration longer than the content's total runtime. A user can't watch more seconds of content than exist in it.

??? question "Which columns do you need and from which tables?"
    - `runtime_minutes` from `stg_streaming__content_catalog`
    - `watch_duration_seconds` from `stg_streaming__watch_event`


You can choose to do this on the *source data*, the *staging model* or *both*.

Create `tests/assert_watch_duration_lte_runtime.sql`.

??? tip "Hint: Test logic"
    ```sql
    -- Returns rows where a watch event is longer than the content's runtime.
    -- Zero rows = test passes.
    select
        -- add select columns here
    from -- use the ref OR source macro
    left join -- use the ref OR source macro
        using -- add the required column
    where -- add the condition where a watch event is longer than the content's runtime.
    ```

    Run it:

    ```bash
    dbt test --select assert_watch_duration_lte_runtime
    ```

    Does it pass on the data? If it fails, look at the failing rows - is it a data quality issue or a logic issue in the test?

??? example "Optional: Write a second singular test"
    Try a second one: assert that no subscription has a `monthly_fee_dollars` of 0 unless the `plan_type` is `trialing`.

    Choose the name of your test and run `dbt test` on that file to check it works.

---

## Step 8 - Run the full test suite

- [ ] Step complete

```bash
dbt test --select +staging.streaming
```

Fix any remaining failures. A test failure is information - read the error, query the failing rows, understand why before changing anything.


---

## Step 9 - BONUS: `dbt build` and check lineage

- [ ] Step complete

```bash
dbt build --select +staging.streaming
```

This runs models and tests together in dependency order. Then open the DAG in dbt Cloud and confirm all three staging models appear with green source nodes from `streaming`.

??? tip "Hint: Generating docs"
    ```bash
    dbt docs generate
    ```

    Now click on the Documentation button - you can find this in the top-left of the console, to the right of the name of your branch. 
    
    You should see `streaming` → `stg_streaming__*` with source nodes shown in green.

??? note "What does the `+` indicate in a dbt command?"
    The `+` selects the model and **all** of its **upstream** (if placed before) or **downstream** (if placed after) dependencies.

---

!!! success "Done?"
    You've added accepted_values tests, relationship integrity checks, normalized messy source data with macros, and written your first custom dbt singular test. These are the building blocks of a production-grade test suite - nicely done!

    Ready for a further challenge? Head to [Level 3](../level3/checklist.md) to configure your tests with severity, `where` clauses, and statistical guardrails from `dbt_expectations`!