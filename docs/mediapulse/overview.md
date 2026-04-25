# MediaPulse - Project Overview

**MediaPulse** is a fictional media company that manages four distinct platforms. Each platform generates its own data, and all four feed into a shared dbt project that your group will work on today.

---

## The business

| Platform | What it does | Raw schema |
|----------|-------------|------------|
| **StreamVault** | Subscription streaming service - films, series, live sport | `streaming` |
| **NewsNow** | Digital news outlet - articles, authors, page views | `news` |
| **PodcastHub** | Podcast network - shows, episodes, listener events | `podcasts` |
| **AdConnect** | Programmatic ad platform - campaigns, impressions, spend | `ads` |

---

## Raw source tables

There are four schemas which hold key data for the company:
- `streaming`
- `news`
- `podcasts`
- `ads`

- `streaming`

    | Table | Key columns | Notes |
    |-------|-------------|-------|
    | `watch_events` | `event_id`, `user_id`, `content_id`, `watched_at`, `watch_duration_seconds`, `device_type` | One row per viewing event; high volume |
    | `subscriptions` | `subscription_id`, `user_id`, `plan_type`, `status`, `started_at`, `ended_at`, `monthly_fee_cents` | Fees stored in cents |
    | `content_catalog` | `content_id`, `title`, `genre`, `content_type`, `release_date`, `runtime_minutes` | Master catalogue |

- `news`

    | Table | Key columns | Notes |
    |-------|-------------|-------|
    | `articles` | `article_id`, `title`, `author_id`, `category`, `published_at`, `updated_at`, `status`, `word_count` | Articles can be republished - duplicates exist |
    | `authors` | `author_id`, `name`, `email`, `joined_at` | Clean; no known issues |
    | `page_views` | `view_id`, `article_id`, `user_id`, `viewed_at`, `referrer_source` | - |

- `podcasts`

    | Table | Key columns | Notes |
    |-------|-------------|-------|
    | `shows` | `show_id`, `show_name`, `host_name`, `category`, `launched_at` | - |
    | `episodes` | `episode_id`, `show_id`, `title`, `published_at`, `duration_seconds`, `season`, `episode_number` | Column naming inconsistency vs. existing staging model |
    | `listens` | `listen_id`, `episode_id`, `user_id`, `listened_at`, `listen_duration_seconds`, `platform` | - |

- `ads`

    | Table | Key columns | Notes |
    |-------|-------------|-------|
    | `campaigns` | `campaign_id`, `advertiser_id`, `campaign_name`, `campaign_type`, `start_date`, `end_date`, `budget_cents` | Budget stored in cents |
    | `impressions` | `impression_id`, `campaign_id`, `content_id`, `impression_date`, `impressions_count`, `clicks` | One row per campaign/content/day |
    | `spend` | `spend_id`, `campaign_id`, `spend_date`, `spend_cents`, `platform_fee_cents` | Daily spend record; can update retroactively |

---

## dbt project structure

```
mediapulse/
├── dbt_project.yml
├── packages.yml
├── models/
│   ├── staging/
│   │   ├── news/
│   │   │   ├── _news__sources.yml          ✅  defined
│   │   │   ├── _news__models.yml           ✅  defined
│   │   │   ├── stg_news__articles.sql      ⚠️  has a bug
│   │   │   └── stg_news__authors.sql       ✅  complete
│   │   ├── podcasts/
│   │   │   ├── _podcasts__sources.yml      ✅  defined
│   │   │   ├── _podcasts__models.yml       ✅  defined
│   │   │   ├── stg_podcasts__episodes.sql  ⚠️  has a bug
│   │   │   └── stg_podcasts__shows.sql     ✅  complete
│   │   ├── streaming/
│   │   │   └── (empty)                     🔲  Group 1's job
│   │   └── ads/
│   │       └── (empty)                     🔲  Group 3's job
│   └── marts/
│       ├── content/
│       │   └── content_performance.sql     ⚠️  incomplete stub
│       └── revenue/
│           └── revenue_by_content.sql      ⚠️  incomplete stub
├── seeds/
│   └── (empty)                             🔲  Groups 2 & 3
├── snapshots/
│   └── (empty)                             🔲  Groups 2 & 3
├── macros/
│   └── (empty)                             🔲  Group 1
└── tests/
    └── (empty)                             🔲  Group 3
```

---

## Getting started

To get started, access the project on dbt Cloud:
- Accept the invite received from your trainer/host to access the Training Account on dbt Cloud. 
- Then login to dbt Cloud and access the project: `MediaPulse - dbt@scale`
- Go to the studio on this project and fill in the username and password credentials.
- Run the below command to make sure your project runs as expected.

```bash
dbt build         # see what breaks (expected at the start!)
```

Your facilitator will provide the username + password needed to connect to the Snowflake warehouse and data.

