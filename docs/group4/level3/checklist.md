# Group 4 - Checklist Level 3

## Advanced Testing + Unit Testing

Start on this checklist once you have completed [Checklist Level 2](../level2/checklist.md).

In this level you will apply the following skills:

- **Test configuration** - project-wide `severity`, `where`, `store_failures` audit
- **Unit testing** - dbt's built-in unit test framework (dbt 1.8+)
- **Testing macros** - verifying logic in isolation before it reaches production

Work through the steps in order. Expand a hint only after you've had a genuine attempt - the struggle is where the learning happens!

---

## Step 1 - Audit test configuration across the project

- [ ] Step complete

You've already run dbt-project-evaluator and fixed documentation and structural issues. Now audit the *quality* of the existing tests - not just whether they exist, but whether they're configured correctly.

Go through all YAML files and answer these questions for each test:

1. Should this test block CI (`error`) or flag for investigation (`warn`)?
2. Are there tests that apply to all rows when they should be scoped with `where`?
3. Which tests, if they failed, would be hardest to debug from a row count alone? Those are candidates for `store_failures`.

Produce a short list of the top 5 changes you'd make across the project and apply them.

??? tip "Hint: Good candidates for severity changes"
    | Test type | Suggested default |
    |-----------|-------------------|
    | `not_null` on primary keys | `error` |
    | `unique` on primary keys | `error` |
    | `relationships` | `error` |
    | `accepted_values` on categories that may grow | `warn` |
    | Row count bounds (`dbt_expectations`) | `warn` |
    | Revenue/money assertions | `error` |

??? tip "Hint: Good candidates for store_failures"
    - Any `relationships` test - which IDs are orphaned?
    - Revenue singular tests - which rows caused the failure?
    - `not_null` on key timestamp columns - which records are missing dates?

---

## Step 2 - Introduction to dbt unit tests

- [ ] Step complete

dbt unit tests (introduced in dbt 1.8) let you test the *logic* of a model in isolation, by providing mock input data and asserting the expected output - without touching the warehouse.

Read through the dbt documentation on unit tests, then answer:

1. What's the difference between a unit test and a data test (generic or singular)?
2. When would you choose a unit test over a data test?
3. What are the limitations of unit tests?

??? tip "Hint: Key distinctions"
    | | Data test | Unit test |
    |-|-----------|-----------|
    | Runs against | Live warehouse data | Mock input rows you define |
    | Tests | Data quality in production | Model transformation logic |
    | Good for | "Is this data correct?" | "Does this SQL do what I think it does?" |
    | Speed | Depends on table size | Always fast (no warehouse scan) |

    Unit tests are most valuable for:
    - Models with complex conditional logic (`CASE WHEN`, `IFF`, multi-step CTEs)
    - Macros that apply transformations across many models
    - Edge cases that don't exist in real data yet (null handling, division by zero guards)

---

## Step 3 - Write a unit test for a staging model transformation

- [ ] Step complete

Write a unit test that verifies the `campaign_type` normalisation logic in `stg_ads__campaigns`. The raw data has mixed casing (`Display`, `VIDEO`, `sponsored_content`) - the model should always produce lowercase, trimmed values.

Create the unit test in `models/staging/ads/_ads__models.yml` (unit tests live in the same YAML as the model they test):

```yaml
unit_tests:
  - name: test_campaign_type_is_normalised
    model: stg_ads__campaigns
    given:
      - input: source('ads', 'campaigns')
        rows:
          - {campaign_id: 'test_1', advertiser_id: 'adv_x', campaign_name: 'Test', campaign_type: 'Display', start_date: '2024-01-01', end_date: '2024-03-31', budget_cents: 100000}
          - {campaign_id: 'test_2', advertiser_id: 'adv_x', campaign_name: 'Test', campaign_type: '  VIDEO  ', start_date: '2024-01-01', end_date: '2024-03-31', budget_cents: 200000}
          - {campaign_id: 'test_3', advertiser_id: 'adv_x', campaign_name: 'Test', campaign_type: 'sponsored_content', start_date: '2024-01-01', end_date: '2024-03-31', budget_cents: 300000}
    expect:
      rows:
        - {campaign_id: 'test_1', campaign_type: 'display'}
        - {campaign_id: 'test_2', campaign_type: 'video'}
        - {campaign_id: 'test_3', campaign_type: 'sponsored_content'}
```

Run it:

```bash
dbt test --select stg_ads__campaigns --indirect-selection=cautious
```

??? tip "Hint: Unit test columns"
    The `expect` block only needs to include the columns you're asserting on - you don't need to specify every output column. dbt compares only the columns you provide in `expect.rows`.

    If the test fails, dbt shows you a diff between what you expected and what the model actually produced - this is much easier to read than a generic test failure.

??? tip "Hint: Running just unit tests"
    ```bash
    dbt test --select stg_ads__campaigns --select test_type:unit
    ```

    Or run all unit tests in the project:

    ```bash
    dbt test --select test_type:unit
    ```

---

## Step 4 - Write a unit test for a macro

- [ ] Step complete

Unit tests can also verify macros, by testing them through a model that uses them. Write a unit test for the `clean_string` macro (written by Group 1) by testing `stg_ads__campaigns` - or, if Group 1's macro isn't available yet, write a simplified inline version directly in the test.

The test should assert that:
- Leading and trailing whitespace is removed
- The result is always lowercase
- A `NULL` input produces an empty string `''` (the `coalesce` guard)

??? tip "Hint: Mocking a macro test"
    If `clean_string` is available in the project, reference a model that calls it.

    If not, you can test the equivalent logic inline:

    ```yaml
    unit_tests:
      - name: test_clean_string_behaviour
        model: stg_ads__campaigns
        given:
          - input: source('ads', 'campaigns')
            rows:
              - {campaign_id: 'c1', campaign_name: '  Test Name  ', campaign_type: 'Display', advertiser_id: 'a', start_date: '2024-01-01', end_date: '2024-01-31', budget_cents: 0}
        expect:
          rows:
            - {campaign_id: 'c1', campaign_type: 'display'}
    ```

    The key insight: a unit test doesn't test the macro in isolation - it tests the *model's behaviour* when given specific inputs. The macro is exercised as part of that.

---

## Step 5 - Write a unit test for the revenue allocation logic

- [ ] Step complete

The impression share calculation in `revenue_by_content` is non-trivial: if one content item gets 3 out of 10 impressions in a campaign on a given day, it should receive 30% of that day's spend.

Write a unit test that verifies this calculation with a controlled, small dataset:

- Campaign `cmp_test` on `2024-02-01` has two content items: `cnt_a` (600 impressions) and `cnt_b` (400 impressions)
- Total campaign impressions: 1000
- Campaign spend on that day: $100.00

Expected output:
- `cnt_a` receives $60.00 in `allocated_spend_dollars`
- `cnt_b` receives $40.00 in `allocated_spend_dollars`

??? tip "Hint: Unit test structure for revenue_by_content"
    This model joins several refs - you'll need to mock all upstream inputs:

    ```yaml
    unit_tests:
      - name: test_impression_share_allocation
        model: revenue_by_content
        given:
          - input: ref('fct_ad_impressions')
            rows:
              - {impression_id: 'i1', campaign_id: 'cmp_test', content_id: 'cnt_a', impression_date: '2024-02-01', impressions_count: 600, clicks: 12, click_through_rate: 0.02, campaign_type: 'display', advertiser_id: 'adv_x'}
              - {impression_id: 'i2', campaign_id: 'cmp_test', content_id: 'cnt_b', impression_date: '2024-02-01', impressions_count: 400, clicks: 8, click_through_rate: 0.02, campaign_type: 'display', advertiser_id: 'adv_x'}
          - input: ref('stg_ads__spend')
            rows:
              - {spend_id: 's1', campaign_id: 'cmp_test', spend_date: '2024-02-01', spend_dollars: 100.00, net_spend_dollars: 85.00, platform_fee_dollars: 15.00}
          - input: ref('stg_ads__campaigns')
            rows:
              - {campaign_id: 'cmp_test', campaign_type: 'display', advertiser_id: 'adv_x', campaign_name: 'Test', start_date: '2024-02-01', end_date: '2024-02-28', budget_dollars: 3000.00}
          - input: ref('commission_lookup')
            rows:
              - {campaign_type: 'display', commission_rate: 0.15}
        expect:
          rows:
            - {content_id: 'cnt_a', allocated_spend_dollars: 60.0}
            - {content_id: 'cnt_b', allocated_spend_dollars: 40.0}
    ```

    If the test fails, read the diff carefully - it tells you exactly which row was wrong and by how much.

---

## Step 6 - Run the full test suite including unit tests

- [ ] Step complete

```bash
dbt build --select +revenue_by_content +content_performance
```

Then run unit tests separately and compare:

```bash
dbt test --select test_type:unit
dbt test --select test_type:generic
```

Discuss:
- Which bugs would unit tests have caught that data tests wouldn't?
- Which bugs would data tests catch that unit tests wouldn't?
- How would you integrate unit tests into your Slim CI job from Level 2?

---

!!! success "Done?"
    You've conducted a project-wide test configuration audit, learned the difference between unit tests and data tests, and written unit tests that verify transformation logic in isolation. Combined with the evaluator work from Level 1 and the dbt-expectations work from Level 2, you now have a full testing toolkit - from structural auditing to statistical guardrails to logic verification.
