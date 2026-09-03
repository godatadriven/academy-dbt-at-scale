# Data Model

## MediaPulse - Base
- **ads** is AdConnect's programmatic ad platform: campaigns, their impressions/clicks, and daily spend.
- **news** is NewsNow's digital news outlet: articles (versioned per edit), authors, and page-view events.
- **streaming** is `StreamVault` (internally PulseStream), MediaPulse's current streaming platform: catalog, subscriptions, and watch events.
- **podcasts** is the PodcastHub's podcast network: shows, episodes, and listen sessions.

## MediaPulse - Analytics

- **Streamview Legacy** is the archived data from `StreamView`, the platform MediaPulse migrated off of.
- The **crm** domain is from `SignalDesk`, the third-party CRM AdConnect's ad sales org uses (system of record since a 2021 migration off a legacy platform called PipelinePro).

## Entity Relationship Diagram

Want to zoom in? [Visit the full ERD here.](https://mermaid.ai/d/e241c203-3583-4e1e-9b21-7bd413a74c00)

```mermaid
erDiagram
    ads.campaigns {
        string campaign_id PK
        string advertiser_id
        string campaign_name
        string campaign_type
        date   start_date
        date   end_date
        int    budget_cents
    }

    ads.impressions {
        string impression_id PK
        string campaign_id   FK
        string content_id    FK
        date   impression_date
        int    impressions_count
        int    clicks
    }

    ads.spend {
        string spend_id    PK
        string campaign_id FK
        date   spend_date
        int    spend_cents
        int    platform_fee_cents
    }

    news.authors {
        string author_id PK
        string name
        string email
        date   joined_at
    }

    news.articles {
        string article_id  PK
        string author_id   FK
        string title
        string category
        date   published_at
        date   updated_at
        string status
        int    word_count
    }

    news.page_views {
        string view_id    PK
        string article_id FK
        string user_id
        date   viewed_at
        string referrer_source
    }

    podcasts.shows {
        string show_id    PK
        string show_name
        string host_name
        string category
        date   launched_at
    }

    podcasts.episodes {
        string episode_id      PK
        string show_id         FK
        string title
        date   published_at
        int    duration_seconds
        string episode_season
        string category
    }

    podcasts.listens {
        string listen_id              PK
        string episode_id             FK
        string user_id
        date   listened_at
        int    listen_duration_seconds
        int    platform_id
    }

    streaming.content_catalog {
        string content_id      PK
        string title
        string genre
        string ctnt_type
        date   release_date
        int    runtime_minutes
    }

    streaming.subscriptions {
        string subscription_id  PK
        string user_id
        string plan_type
        string status
        date   start_date
        string start_time
        date   end_date
        string end_time
        int    monthly_fee_cents
        date   updated_at
    }

    streaming.watch_events {
        string event_id              PK
        string user_id
        string content_id            FK
        date   watched_at
        int    watch_duration_seconds
        string device_type
        date   batched_at
    }

    streamview_legacy.media_catalog_archive {
        string media_id      PK
        string media_title
        string category
        string media_format
        date   release_dt
        int    duration_min
    }

    streamview_legacy.acct_subs_archive {
        string subscriber_ref  PK
        string tier
        string account_status
        date   start_dt
        string start_tm
        date   end_dt
        string end_tm
    }

    streamview_legacy.playback_heartbeats {
        string ping_id                    PK
        string subscriber_ref             FK
        string media_id                   FK
        date   ping_date
        string ping_time
        int    playback_position_seconds
        string device_code
    }

    crm.sales_reps {
        string rep_id      PK
        string rep_name
        string region
        date   hire_date
    }

    crm.advertiser_accounts {
        string advertiser_id  PK
        string advertiser_name
        string industry
        string sales_rep_id   FK
        string contract_tier
        string account_status
        date   signed_at
    }

    crm.contracts {
        string contract_id           PK
        string advertiser_id         FK
        int    contract_value_cents
        date   start_date
        date   end_date
        string renewal_status
    }

    crm.touchpoints {
        string touchpoint_id  PK
        string advertiser_id  FK
        string rep_id         FK
        string touchpoint_type
        date   occurred_at
        string notes
    }

    streaming.content_catalog ||--o{ streaming.watch_events : "watched as"
    crm.sales_reps            ||--o{ crm.advertiser_accounts : "manages"
    crm.advertiser_accounts   ||--o{ crm.contracts            : "signs"
    crm.advertiser_accounts   ||--o{ crm.touchpoints          : "receives"
    crm.sales_reps            ||--o{ crm.touchpoints          : "logs"
    crm.advertiser_accounts   ||--o{ ads.campaigns            : "runs"
    streamview_legacy.media_catalog_archive ||--o{ streamview_legacy.playback_heartbeats : "pinged as"
    streamview_legacy.acct_subs_archive      ||--o{ streamview_legacy.playback_heartbeats : "pinged by"
    ads.campaigns        ||--o{ ads.impressions           : "generates"
    ads.campaigns        ||--o{ ads.spend                 : "incurs"
    streaming.content_catalog ||--o{ ads.impressions      : "appears in"
    news.authors         ||--o{ news.articles             : "writes"
    news.articles        ||--o{ news.page_views           : "receives"
    podcasts.shows       ||--o{ podcasts.episodes         : "publishes"
    podcasts.episodes    ||--o{ podcasts.listens          : "recorded as"
```

## Domains

### Ads
| Table | Description |
|---|---|
| `ads.campaigns` | Advertiser campaigns with budget and date range |
| `ads.impressions` | Impressions and clicks per campaign and content item |
| `ads.spend` | Daily spend and platform fees per campaign |

### News
| Table | Description |
|---|---|
| `news.authors` | Author profiles |
| `news.articles` | Articles with author, category, and status |
| `news.page_views` | Page view events per article and user |

### Podcasts
| Table | Description |
|---|---|
| `podcasts.shows` | Podcast show metadata |
| `podcasts.episodes` | Episodes with season, category, and duration |
| `podcasts.listens` | Listen events per episode and user, with a numeric `platform_id` |

### Streaming
| Table | Description |
|---|---|
| `streaming.content_catalog` | Video content with genre and runtime |
| `streaming.subscriptions` | User subscription plans and status |
| `streaming.watch_events` | Watch events per content item and user |

### Streamview Legacy
| Table | Description |
|---|---|
| `streamview_legacy.media_catalog_archive` | Legacy content catalog, some items re-catalogued under a new `content_id` |
| `streamview_legacy.acct_subs_archive` | Legacy subscriber accounts, some migrated to a new `user_id` |
| `streamview_legacy.playback_heartbeats` | Playback heartbeat pings, roughly one per minute of playback (not one row per completed watch, unlike `streaming.watch_events`) |

### CRM
| Table | Description |
|---|---|
| `crm.sales_reps` | AdConnect sales rep profiles |
| `crm.advertiser_accounts` | Advertiser accounts, tier, and status, one row per advertiser |
| `crm.contracts` | Advertiser contract terms and value |
| `crm.touchpoints` | Sales activity (calls, emails, meetings, demos) per advertiser and rep |

## Cross-domain Relationships

`ads.impressions` links to `streaming.content_catalog` via `content_id`, meaning ad impressions are served against streaming content items.

`crm.advertiser_accounts` links to `ads.campaigns` via `advertiser_id` - the same advertiser identifier is shared across the CRM and ads domains, even though the two are otherwise unconnected.

!!! note "Streamview Legacy migration"
    `streamview_legacy` has no direct FK into `streaming` - the two are reconciled through a separate mapping seed (`map_streaming_legacy_fields`) that isn't raw source data, so it isn't drawn here. Not every legacy subscriber or content item has been migrated yet.

!!! note "Users"
    `user_id` appears in `news.page_views`, `podcasts.listens`, `streaming.subscriptions`, and `streaming.watch_events` but there is no `users` table in the raw data. A unified users table may exist upstream.
