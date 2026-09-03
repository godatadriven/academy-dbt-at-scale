# mediapulse_base

A dbt project that models MediaPulse's core content and advertising domains: news, podcasts, streaming, and ads. It owns the staging, intermediate, and marts layers for these domains and exposes shared dimensions and building blocks that other dbt projects can build on.

## Structure

```
models/
├── staging/
│   ├── ads/          campaigns, impressions, spend
│   ├── news/          articles, authors, page_views
│   ├── podcasts/     shows, episodes, listens
│   └── streaming/    content_ctlg, subscriptions_lifecycle_rec, usr_watch_events_log
├── intermediate/
│   ├── int_campaign_content_spend_allocation
│   ├── int_dedupe_subscribers
│   ├── int_news__articles_deduped
│   └── int_shows_clean_string_columns
└── marts/
    ├── ads/          dim_campaigns, fct_ad_impressions
    ├── news/          dim_authors, fct_news_page_views
    ├── podcasts/     dim_shows, fct_podcast_listens
    ├── streaming/    dim_content_catalog, dim_subscriptions, fct_streaming_events
    └── dim_dates.sql
```

Materialization defaults, set in `dbt_project.yml`:

| Layer | Materialization | Access |
|---|---|---|
| staging | view | public |
| intermediate | view | protected |
| marts | table | protected |

`protected` is the dbt default and means these models can be referenced anywhere within `mediapulse_base`, but not from another dbt project unless a model overrides its access to `public`.

## Marts

Ten marts across four domains:

- **ads** - `dim_campaigns` (conformed campaign dimension), `fct_ad_impressions` (one row per campaign/content impression, with click-through rate)
- **news** - `dim_authors` (with article output stats), `fct_news_page_views` (one row per article view)
- **podcasts** - `dim_shows` (with episode output stats), `fct_podcast_listens` (one row per listen session, with completion rate)
- **streaming** - `dim_content_catalog`, `dim_subscriptions` (lifecycle timestamps, current-status flag), `fct_streaming_events` (watch events enriched with content and subscription details)
- **shared** - `dim_dates`, a calendar spine both this project and `mediapulse_analytics` are meant to join to

`stg_ads__campaigns`, `stg_ads__impressions`, and `stg_ads__spend` read directly from the raw `ads` tables rather than through a `source()` definition.

## How this relates to mediapulse_analytics

`mediapulse_analytics` is a separate dbt project that declares this project as a dbt Mesh dependency (see its `dependencies.yml`). It resolves `ref()` calls to models such as `stg_news__articles`, `stg_podcasts__episodes`, `stg_ads__campaigns`, and `stg_ads__spend` against this project instead of defining its own staging layer for those domains. `mediapulse_base` has no dependency in the other direction and does not reference anything from `mediapulse_analytics`.

## Streaming domain availability

The `streaming` marts (`dim_content_catalog`, `dim_subscriptions`, `fct_streaming_events`) are currently `access: protected`, like every other mart in this project - `mediapulse_analytics` can't `ref()` them at all yet. That's deliberate, not an oversight: `fct_streaming_events`'s description documents a known, unresolved join fan-out (subscriptions are joined on `user_id` with no date-range filter), and we haven't shipped a fix.

The plan is to fix the fan-out, let a couple of clean production runs land, then flip the streaming marts - `fct_streaming_events` in particular - to `access: public` and formally announce them as ready for cross-project consumption by the start of Q3 2027. If another project wants to build on the current streaming platform's data before then, talk to us first.

## Setup

1. Open the Studio in dbt Platform
2. Click on status in the bottom right - it should say error
3. Click on view credentials, make sure Snowflake SSO is selected, then sign in to Snowflake.
4. Run `dbt deps` to install `dbt_utils` and `codegen`.
5. Run `dbt build` to ensure the project can be executed (there may be failures in the models)
