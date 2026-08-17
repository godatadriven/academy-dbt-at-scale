# mediapulse_analytics

A dbt project that builds cross-domain analytics marts for MediaPulse: content performance across news and podcasts, and ad revenue by campaign. It has no staging layer or sources of its own; it consumes staging models owned by `mediapulse_platform` through a dbt Mesh dependency.

## Structure

```
models/
├── staging/
│   ├── streaming_legacy/     
├── intermediate/    
└── marts/
```

`dbt_project.yml` sets `marts` to materialize as tables. There's a `raw_database: "RAW"` var defined but nothing in this project currently reads it, since there are no local source definitions.

## Cross-project dependency

`dependencies.yml` declares `mediapulse_platform` as a dbt Mesh project dependency:

```yaml
projects:
  - name: mediapulse_platform
```

This lets `ref()` calls in this project resolve to models defined in `mediapulse_platform` rather than requiring their own copies. 

## Setup

1. Open the Studio in dbt Platform
2. Click on status in the bottom right - it should say error
3. Click on view credentials, make sure Snowflake SSO is selected, then sign in to Snowflake.
2. Run `dbt deps` to install `dbt_utils` and `codegen`.
4. Run `dbt build` to ensure the project can be executed (there may be failures in the models)