# set_up_project

This project doesn't model anything itself - it exists to load the raw data that `mediapulse_base` and `mediapulse_analytics` both read from. Run this project first; the other two won't have any source data to build from until you do.

## What it does

It's a seeds-only dbt project. Every CSV in `seeds/_seeds_setup/` simulates a raw upstream table (news, podcasts, streaming, ads, the StreamView legacy archive, and CRM), and `_seeds_setup.yml` pins each seed's `database`, `schema`, and `alias` so it lands exactly where the other two projects' source definitions expect to find it - in the shared `mediapulse_raw` database, in the schema and under the table name their `sources.yml` files declare.

That's the whole mechanism: there's no external ingestion layer for this workshop, so `dbt seed` here *is* "the data pipeline landing raw data in the warehouse." Once it's run, `mediapulse_base`'s and `mediapulse_analytics`'s `source()` calls resolve against real rows.

A couple of domains ship two versions of the same seed (`raw_news__articles`/`raw_news__articles_updated`, `raw_podcasts__episodes`/`raw_podcasts__episodes_updated`) - the `_updated` variants simulate what the source table looks like after upstream changes, and are used later in the Group 2 snapshot exercises to demonstrate SCD Type 2 behaviour.

## Structure

```
seeds/
└── _seeds_setup/
    ├── raw_news__*.csv
    ├── raw_podcasts__*.csv
    ├── raw_streaming__*.csv
    ├── raw_ads__*.csv
    ├── raw_legacy_streaming__*.csv     # StreamView legacy archive
    ├── raw_crm__*.csv                  # advertiser CRM
    └── _seeds_setup.yml                # per-seed database/schema/alias config
```

## Setup

1. Open the Studio in dbt Platform
2. Click on status in the bottom right - it should say error
3. Click on view credentials, make sure Snowflake SSO is selected, then sign in to Snowflake.
4. Run `dbt deps` to install `dbt_utils` and `codegen`.
5. Run `dbt seed` to load the raw CSVs into `mediapulse_raw`.
6. Only once this succeeds, move on to setting up `mediapulse_base` and `mediapulse_analytics` - their models will fail to find source data until these seeds exist.
