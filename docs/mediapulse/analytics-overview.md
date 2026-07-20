# MediaPulse Analytics - Project Overview

`mediapulse_analytics` is the downstream dbt project. It owns the business-specific mart models, commission lookup seed, campaign snapshots, and singular tests. It depends on `mediapulse_platform` via dbt mesh cross-project references.

---

## Getting started

Access the project on dbt Cloud:

1. Accept the invite from your trainer to access the Training Account on dbt Cloud.
2. Log in to dbt Cloud and open the project **MediaPulse Analytics**.
3. Open the IDE and fill in your username and password credentials.
4. Run the command below to see what the project looks like at the start of the workshop.

```bash
dbt build
```

Your facilitator will provide the Snowflake username and password.

---

## Project structure

```
mediapulse_analytics/
├── dbt_project.yml
├── packages.yml
├── dependencies.yml         declares mediapulse_platform as an upstream project
├── models/
│   └── marts/
│       ├── content/
│       │   └── fct_content_performance.sql     incomplete, has a logic bug
│       └── revenue/
│           ├── fct_ad_revenue.sql               incomplete, grain is wrong
│           └── fct_campaign_daily_performance.sql   missing - Group 4's capstone
├── seeds/                   empty - commission_lookup.csv goes here (Group 3)
├── snapshots/               empty - snap_ads__campaigns goes here (Group 3)
└── tests/                   empty - singular tests go here (Group 3)
```

---

## Who owns what

| Asset | Status | Group |
|-------|--------|-------|
| `fct_content_performance.sql` | Logic bug preserved | Group 3 rewires with cross-project refs |
| `fct_ad_revenue.sql` | Grain bug preserved | Group 3 fixes and extends |
| `fct_campaign_daily_performance.sql` | Missing | Group 4's capstone - see [Group 4 Level 2](../group4/level2/checklist.md) |
| `seeds/commission_lookup.csv` | Not yet created | Group 3 adds |
| `snapshots/snap_ads__campaigns` | Not yet created | Group 3 adds |
| `tests/` | Empty | Group 3 adds singular tests |

Groups 3 and 4 also wire this project to consume public models from `mediapulse_platform` via cross-project refs, and set up CI/CD jobs for both projects.

---

## Cross-project references

`mediapulse_analytics` depends on `mediapulse_platform`. Once the platform project exposes models as public (with contracts), the analytics project can reference them using the cross-project ref syntax:

```sql
{{ ref('mediapulse_platform', 'stg_news__articles') }}
```

This is what Groups 3 and 4 set up. The `dependencies.yml` file already declares the upstream project. What still needs to happen is:

1. The platform team (Groups 3/4) adds model access controls and contracts to the staging models.
2. The analytics team (Groups 3/4) updates the mart models to use cross-project refs instead of local `ref()` calls.

See the [dbt mesh documentation](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-1-intro) for the full setup guide.

---

## Known issues (intentional)

| Model | Issue |
|-------|-------|
| `fct_content_performance.sql` | Uses an `INNER JOIN` between articles and episodes instead of `UNION ALL`, causing a cross-join explosion |
| `fct_ad_revenue.sql` | Aggregates at campaign grain, losing the per-content breakdown the mart name promises |
| `fct_campaign_daily_performance.sql` | Missing entirely - Group 4's capstone. See [Group 4 Level 2](../group4/level2/checklist.md). |

Both bugs are preserved intentionally. Diagnosing and fixing them is part of the Group 3 exercise.
