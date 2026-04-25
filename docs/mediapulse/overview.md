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

## Known issues (intentionally baked in)

!!! warning "Spoiler territory"
    These are documented here for facilitators and for groups whose work depends on a fixed upstream model. Students should discover these bugs themselves from their checklist - don't read ahead if you don't want to spoil the investigation.

??? bug "Bug 1 - `stg_news__articles.sql`: missing deduplication"
    The `news.articles` table contains duplicate `article_id` values because articles can be republished with an updated `updated_at` timestamp. The staging model selects all rows without deduplication, causing downstream fans when joined.

    **Fix:** add a `ROW_NUMBER()` window function partitioned by `article_id`, ordered by `updated_at DESC`, and filter to `row_num = 1`.

??? bug "Bug 2 - `stg_podcasts__episodes.sql`: wrong column name"
    The model references `episode_name` in its `SELECT`, but the raw table column is named `title`. This causes a compile/run error.

    **Fix:** replace `episode_name` with `title`.

??? bug "Bug 3 - `content_performance.sql` stub: incorrect join type"
    The stub mart uses an `INNER JOIN` between `stg_news__articles` and `stg_podcasts__episodes`, which produces no rows because the join key (`category`) is not a foreign-key relationship between these two tables. They should be `UNION ALL`-ed after normalising columns, then joined to the category seed.

??? bug "Bug 4 - `revenue_by_content.sql` stub: wrong aggregation grain"
    The stub aggregates spend at `campaign_id` grain, losing the per-content breakdown. Revenue should be allocated per `content_id` via the impressions table before joining to campaign spend.

---

## Getting started

```bash
# From the mediapulse/ dbt project root
dbt deps          # install packages
dbt debug         # confirm connection
dbt build         # see what breaks (expected at start!)
```

Your facilitator will provide connection credentials and the dbt Cloud project URL before the first breakout session.

