# Group 3 - Advanced II: Incremental Models, Singular Tests & Revenue Analytics

## Your slice of MediaPulse

You own the **revenue** story - how much money MediaPulse makes through AdConnect, and how that revenue maps back to the content it runs against. The ad platform generates huge volumes of impression data, making it a perfect candidate for incremental loading. You'll also track how advertiser budgets shift over time and write custom tests to validate your revenue numbers.

!!! warning "Group size note"
    This group has 11–13 participants and may be split into two sub-groups based on a pre-assessment. Your facilitator will confirm before the first breakout.

---

## Learning objectives

By the end of the hackathon you will be able to:

- Define sources and build staging models for the **ads** domain
- Implement an **incremental model** with a correct `unique_key` and `is_incremental()` filter
- Understand the trade-offs between incremental strategies (`append`, `merge`, `insert_overwrite`)
- Build a **revenue mart** that allocates ad spend to content via impressions
- Create a **snapshot** to track advertiser campaign budget changes
- Write **singular (custom) tests** that express business logic as SQL assertions
- Load a **seed** for commission/rate lookups

---

## Key concepts

### Incremental models

An incremental model only processes new or changed rows on subsequent runs, making it practical for high-volume fact tables.

```sql
{{
    config(
        materialized='incremental',
        unique_key='impression_id',
        incremental_strategy='merge'
    )
}}

select
    impression_id,
    campaign_id,
    content_id,
    impression_date,
    impressions_count,
    clicks
from {{ source('ads', 'impressions') }}

{% if is_incremental() %}
    where impression_date >= (select max(impression_date) from {{ this }})
{% endif %}
```

On the **first run** the `{% if is_incremental() %}` block is skipped - the full history loads. On every **subsequent run** only new records are processed.

### Singular tests

Singular tests are plain SQL files in `tests/`. A test **passes** when the query returns zero rows.

```sql
-- tests/assert_no_negative_spend.sql
select spend_id
from {{ ref('stg_ads__spend') }}
where spend_cents < 0
```

Use singular tests when generic tests can't express the rule - e.g. cross-model consistency checks or complex aggregation assertions.

### Revenue allocation

Ad spend sits at `campaign_id` grain. Content performance sits at `content_id` grain. To link them you need the `impressions` table, which records how many times each `campaign_id` ran against each `content_id`. Allocate spend proportionally:

```
content_revenue = campaign_spend × (content_impressions / total_campaign_impressions)
```

---

## Relevant tables

All in `ads` - none wired into dbt yet:

- `ads.campaigns`
- `ads.impressions`
- `ads.spend`

See the [MediaPulse overview](../mediapulse/overview.md) for full column details.

---

## Time guide

| Session | Target |
|---------|--------|
| Day 1 AM (10:00–12:00) | Steps 1–6: sources, seed, staging models |
| Day 1 PM (13:30–16:30) | Steps 7–14: incremental fact, mart, snapshot, singular tests |

Head to the [Checklist](level1/checklist.md) when you're ready to start.

