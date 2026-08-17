# mediapulse_platform

A dbt project that models MediaPulse's core content and advertising domains: news, podcasts, and ads. It owns the staging, intermediate, and marts layers for these domains and exposes shared dimensions and building blocks that other dbt projects can build on.

Streaming has raw seed data and a `models/staging/streaming/` folder but no models yet.

## Structure

```
models/
├── staging/
│   ├── ads/
│   ├── news/
│   ├── podcasts/
│   └── streaming/
├── intermediate/
└── marts/
    ├── ads/
    └── dim_dates.sql
```

Materialization defaults, set in `dbt_project.yml`:

| Layer | Materialization | Access |
|---|---|---|
| staging | view | public |
| intermediate | view | protected |
| marts | table | protected |

`protected` is the dbt default and means these models can be referenced anywhere within `mediapulse_platform`, but not from another dbt project unless a model overrides its access to `public`. 

## Setup

1. Open the Studio in dbt Platform
2. Click on status in the bottom right - it should say error
3. Click on view credentials, make sure Snowflake SSO is selected, then sign in to Snowflake.
2. Run `dbt deps` to install `dbt_utils` and `codegen`.
4. Run `dbt build` to ensure the project can be executed (there may be failures in the models)
