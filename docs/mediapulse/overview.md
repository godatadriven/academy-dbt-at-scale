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

    | Table | Key columns |
    |-------|-------------|
    | `watch_events` | `event_id`, `user_id`, `content_id`, `watched_at`, `watch_duration_seconds`, `device_type` |
    | `subscriptions` | `subscription_id`, `user_id`, `plan_type`, `status`, `started_at`, `ended_at`, `monthly_fee_cents` |
    | `content_catalog` | `content_id`, `title`, `genre`, `content_type`, `release_date`, `runtime_minutes` |

- `news`

    | Table | Key columns |
    |-------|-------------|
    | `articles` | `article_id`, `title`, `author_id`, `category`, `published_at`, `updated_at`, `status`, `word_count` |
    | `authors` | `author_id`, `name`, `email`, `joined_at` |
    | `page_views` | `view_id`, `article_id`, `user_id`, `viewed_at`, `referrer_source` |

- `podcasts`

    | Table | Key columns |
    |-------|-------------|
    | `shows` | `show_id`, `show_name`, `host_name`, `category`, `launched_at` |
    | `episodes` | `episode_id`, `show_id`, `title`, `published_at`, `duration_seconds`, `season`, `episode_number` |
    | `listens` | `listen_id`, `episode_id`, `user_id`, `listened_at`, `listen_duration_seconds`, `platform` |

- `ads`

    | Table | Key columns |
    |-------|-------------|
    | `campaigns` | `campaign_id`, `advertiser_id`, `campaign_name`, `campaign_type`, `start_date`, `end_date`, `budget_cents` |
    | `impressions` | `impression_id`, `campaign_id`, `content_id`, `impression_date`, `impressions_count`, `clicks` |
    | `spend` | `spend_id`, `campaign_id`, `spend_date`, `spend_cents`, `platform_fee_cents` |

---

## dbt project structure

The workshop now runs on two dbt projects connected by **dbt Mesh**, rather than the single `mediapulse/` project used in earlier versions of this workshop. If you see references to a single `mediapulse/` project elsewhere (older material, recordings, etc.), treat this page as the current source of truth.

- **`mediapulse_base`** - owns the staging → intermediate → marts layering for news, podcasts, streaming, and ads. This is the producer project: most of the raw-data modelling work lives here, and it already has a working (if imperfect) layer for every domain.
- **`mediapulse_analytics`** - a second, smaller project. It declares `mediapulse_base` as a project dependency (`dependencies.yml`) and consumes its `public`-access models via cross-project `ref()` for two of its marts (`fct_content_performance`, `fct_ad_revenue`). It also owns two fully self-contained domains of its own - an advertiser CRM domain and a StreamView legacy-migration domain - that read directly from raw sources and don't depend on `mediapulse_base` at all.

Both projects already have working models end to end - nobody is starting from an empty folder. Some models carry deliberate, documented gaps and rough edges (missing tests, a known join bug in `fct_content_performance`, an access-level inconsistency on `dim_campaigns`, and so on) for you to find and reason about as part of your group's exercises. See `mediapulse_base/README.md` and `mediapulse_analytics/README.md` for each project's own structure, and your group's overview page for what you'll specifically be doing with them.

---

## Getting started

To get started, access the projects on dbt Cloud:
- Accept the invite received from your trainer/host to access the Training Account on dbt Cloud.
- Then login to dbt Cloud - you'll see both `mediapulse_base` and `mediapulse_analytics` listed as projects.
- Go to the Studio on each project and fill in the username and password credentials.
- Run the below command in each project to make sure it runs as expected.

```bash
dbt build         # see what breaks (expected at the start!)
```

Your facilitator will provide the username + password needed to connect to the Snowflake warehouse and data.

