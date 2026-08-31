# mediapulse_analytics

A dbt project that builds cross-domain analytics marts for MediaPulse: content performance across news and podcasts, ad revenue by campaign, a StreamView legacy-migration domain, and an advertiser CRM domain. The content and revenue marts have no staging layer or sources of their own; they consume staging models owned by `mediapulse_base` through a dbt Mesh dependency. The legacy and CRM domains are fully self-contained, with their own sources, seeds, staging, and marts local to this project.

## Structure

```
models/
├── staging/
│   ├── streamview_legacy/    content, subscriptions, watch_pings
│   └── crm/                  sales_reps, advertiser_accounts, contracts, touchpoints
└── marts/
    ├── content/               fct_content_performance
    ├── revenue/               fct_ad_revenue
    ├── streamview_legacy/     dim_legacy_content, dim_legacy_subscribers,
    │                          fct_legacy_subscription_lifecycle_events, fct_legacy_watch_events
    └── crm/                   dim_advertisers, dim_sales_reps,
                               fct_advertiser_contracts, fct_crm_touchpoints
```

`dbt_project.yml` sets `staging` to materialize as views and `marts` as tables. There's a `raw_database: "RAW"` var defined but nothing in this project currently reads it.

## Marts

Ten marts across four domains:

- **content** (cross-project) - `fct_content_performance`, combining NewsNow articles and PodcastHub episodes
- **revenue** (cross-project) - `fct_ad_revenue`, AdConnect spend rolled up by campaign
- **streamview_legacy** (local) - `dim_legacy_content` and `dim_legacy_subscribers` (resolved to current MediaPulse ids where a mapping exists), `fct_legacy_subscription_lifecycle_events` (unpivoted start/end events), `fct_legacy_watch_events` (playback heartbeat pings)
- **crm** (local) - `dim_advertisers`, `dim_sales_reps`, `fct_advertiser_contracts`, `fct_crm_touchpoints`, tracking the advertiser accounts also seen in the ads domain's `advertiser_id`

The legacy domain reads from the `streamview_legacy` schema in `mediapulse_raw` (the archive tables StreamView is being migrated off of) and resolves legacy ids to current MediaPulse ids using the `map_streaming_legacy_fields` seed - not every legacy subscriber or content item has been migrated yet, so `is_mapped` can be false.

## Cross-project dependency

`dependencies.yml` declares `mediapulse_base` as a dbt Mesh project dependency:

```yaml
projects:
  - name: mediapulse_base
```

This lets `ref()` calls in `fct_content_performance` and `fct_ad_revenue` resolve to staging models defined in `mediapulse_base` rather than requiring their own copies. The `streamview_legacy` and `crm` domains don't use this dependency at all - they only read from their own sources and seeds.

## Sources

### SignalDesk - CRM System

Our CRM data is sourced from **SignalDesk**, the ad sales org's system of record since the 2021 migration off the legacy **PipelinePro** platform. 
SignalDesk exports advertiser accounts, contracts, sales rep records, and sales touchpoints (calls, emails, meetings, demos) nightly via a vendor-managed extract. 
We do not own this system - **RevOps** and the **SignalDesk** vendor team do - which means schema changes reach us as a heads-up in a Slack channel. 
The staging models in this project - `stg_crm__*` - absorb that unpredictability before it reaches anything downstream.

#### Known Caveats and upcoming changes in source

This is a note from **SignalDesk** team that ingests the source data:

> Hey team - heads up on a few fields, since we have some caveats and want to inform you of some known some changes are coming.
> - `contract_value_cents` is stored in cents, not dollars, a holdover from PipelinePro's original schema that SignalDesk never converted during migration. Divide by 100 downstream - don't assume the column name lies.
> - **Timestamp fields** (`hire_date`, `signed_at`, `start_date`, `end_date`, `occurred_at`) are exported in the CRM's local server time and not UTC. 
> - `account_status` currently sends `active`, `at_risk`, `churned`. We're rolling out a **dunning-workflow feature** in two stages over the next two quarters. Naming conventions are locked in, just not live yet.
>   - **Stage 1**: Includes the value `paused`, 
>   - **Stage 2**: Includes `flagged_for_review`. 
> - `renewal_status` is getting the same two-stage treatment, same timeline. Naming also locked in but not yet live.
>   - **Stage 1**: Includes the value `pending_renewal`, 
>   - **Stage 2**: Includes `in_negotiation`. 
> - `touchpoint_type` is changing too, but the taxonomy review is still under discussion, so we can't hand you a list of new values just yet. Just keep in mind that new values will show up at some point, probably a couple at a time rather than all at once. If you see anything new, you can run it by us to confirm it was intentional on our end or an error.
> - `contract_tier` will be affected by the migration of our ingestion engine this year. Tier values aren't changing, we can't currently guarantee consistent casing through the transition. You might see `Gold` from some pipelines and `gold` from others for a while.
>
> Last thing - if you ever spot bad data from us (a stray value, something that looks like a bug rather than a planned change, etc.), please document this - in SQL table(s) is fine. 
> We want to align with any errors caught on either side (with us and within your dbt projects) so we can keep improving what we hand off to you.
>
> - RevOps / SignalDesk data team


## Setup

1. Open the Studio in dbt Platform
2. Click on status in the bottom right - it should say error
3. Click on view credentials, make sure Snowflake SSO is selected, then sign in to Snowflake.
2. Run `dbt deps` to install `dbt_utils` and `codegen`.
4. Run `dbt build` to ensure the project can be executed (there may be failures in the models)
