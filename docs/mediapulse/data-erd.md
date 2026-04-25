# Data Model

This page documents the raw data model across all four source domains: **Ads**, **News**, **Podcasts**, and **Streaming**.

## Entity Relationship Diagram

Want to zoom in? [Visit the full ERD here.](https://mermaid.ai/d/22057612-b758-4939-8126-0538daeb0906)

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
        int    season
        int    episode_number
    }

    podcasts.listens {
        string listen_id              PK
        string episode_id             FK
        string user_id
        date   listened_at
        int    listen_duration_seconds
        string platform
    }

    streaming.content_catalog {
        string content_id      PK
        string title
        string genre
        string content_type
        date   release_date
        int    runtime_minutes
    }

    streaming.subscriptions {
        string subscription_id  PK
        string user_id
        string plan_type
        string status
        date   started_at
        date   ended_at
        int    monthly_fee_cents
    }

    streaming.watch_events {
        string event_id              PK
        string user_id
        string content_id            FK
        date   watched_at
        int    watch_duration_seconds
        string device_type
    }

    streaming.content_catalog ||--o{ streaming.watch_events : "watched as"
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
| `podcasts.episodes` | Episodes with season, number, and duration |
| `podcasts.listens` | Listen events per episode and user |

### Streaming
| Table | Description |
|---|---|
| `streaming.content_catalog` | Video content with genre and runtime |
| `streaming.subscriptions` | User subscription plans and status |
| `streaming.watch_events` | Watch events per content item and user |

## Cross-domain Relationships

`ads.impressions` links to `streaming.content_catalog` via `content_id`, meaning ad impressions are served against streaming content items.

!!! note "Users"
    `user_id` appears in `news.page_views`, `podcasts.listens`, `streaming.subscriptions`, and `streaming.watch_events` but there is no `users` table in the raw data. A unified users table may exist upstream.
