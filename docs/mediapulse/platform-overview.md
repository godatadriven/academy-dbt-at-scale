# MediaPulse Platform - Project Overview

`mediapulse_platform` is the upstream dbt project. It owns all source-aligned staging models, intermediate calculations, shared macros, and the setup seed data. It is the trusted data contract boundary that the analytics project depends on.

---

## Getting started

Access the project on dbt Cloud:

1. Accept the invite from your trainer to access the Training Account on dbt Cloud.
2. Log in to dbt Cloud and open the project **MediaPulse Platform**.
3. Open the IDE and fill in your username and password credentials.
4. Run the command below to see what the project looks like at the start of the workshop.

```bash
dbt build
```

Your facilitator will provide the Snowflake username and password.

---

## Project structure

```
mediapulse_platform/
├── dbt_project.yml
├── packages.yml
├── models/
│   ├── staging/
│   │   ├── news/
│   │   │   ├── _news__sources.yml          defined
│   │   │   ├── _news__models.yml           defined
│   │   │   ├── stg_news__articles.sql      has a bug
│   │   │   └── stg_news__authors.sql       complete
│   │   ├── podcasts/
│   │   │   ├── _podcasts__sources.yml      defined
│   │   │   ├── _podcasts__models.yml       defined
│   │   │   ├── stg_podcasts__episodes.sql  has a bug
│   │   │   └── stg_podcasts__shows.sql     complete
│   │   ├── streaming/
│   │   │   └── (empty)                     Group 1's job
│   │   └── ads/
│   │       ├── stg_ads__campaigns.sql      complete
│   │       ├── stg_ads__impressions.sql    complete
│   │       └── stg_ads__spend.sql          complete
│   ├── intermediate/
│   │   ├── int_campaign_content_spend_allocation.sql
│   │   └── int_episode_listen_completion.sql
│   └── marts/
│       ├── _marts__models.yml                    defined
│       ├── dim_dates.sql                         complete
│       ├── ads/
│       │   ├── dim_campaigns.sql                 complete
│       │   └── fct_ad_impressions.sql            missing - Group 3's capstone
│       ├── streaming/
│       │   └── fct_streaming_engagement.sql      missing - Group 1's capstone
│       └── content/
│           └── fct_content_engagement.sql        missing - Group 2's capstone
├── macros/
│   └── generate_schema_name.sql
├── seeds/
│   └── _seeds_setup/       setup data for the workshop (do not modify)
├── snapshots/               empty - Groups 1 and 2 add here
└── tests/                   empty
```

---

## Who owns what

| Domain | Models | Group |
|--------|--------|-------|
| streaming | staging (empty, to be built), `fct_streaming_engagement` (missing) | Group 1 |
| news | staging (has bugs), snapshots, `fct_content_engagement` (missing) | Group 1 and Group 2 |
| podcasts | staging (has bugs), intermediate, `fct_content_engagement` (missing) | Group 2 |
| ads | staging (complete, to be wired with source), `dim_campaigns` (complete), `fct_ad_impressions` (missing) | Group 3 |
| intermediate | intermediate calculations | Group 2 may extend |
| marts (shared) | `dim_dates`, `dim_campaigns` | Complete - built for you |

Groups 3 and 4 audit and harden the whole platform project, and add model contracts and access controls so the analytics project can consume public models.

---

## Known issues (intentional)

| Model | Status | Issue |
|-------|--------|-------|
| `stg_news__articles.sql` | Has a bug | Run it and read the error |
| `stg_podcasts__episodes.sql` | Has a bug | Run it and read the error |
| `models/staging/streaming/` | Empty | Group 1 builds this |
| `models/staging/ads/` | Staging models exist, source definition missing | Group 3 adds `_ads__sources.yml` |
| `snapshots/` | Empty | Groups 1 and 2 add snapshots |
| `fct_streaming_engagement` | Missing | Group 1's capstone - see [Group 1 Level 3](../group1/level3/checklist.md) |
| `fct_content_engagement` | Missing | Group 2's capstone - see [Group 2 Level 3](../group2/level3/checklist.md) |
| `fct_ad_impressions` | Missing | Group 3's capstone - see [Group 3 Level 2](../group3/level2/checklist.md) |

The bugs are intentional. Reading error messages and diagnosing root causes is a core part of the workshop. `dim_dates` and `dim_campaigns` are complete, working models - use them as a reference for what a finished, documented, tested mart model looks like, and join to them from the facts you build.
