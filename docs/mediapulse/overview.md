# MediaPulse - Project Overview

**MediaPulse** is a fictional media company that manages four core platforms, plus data from a third-party CRM vendor and an archived legacy platform it migrated off of. All of it lands in two connected dbt projects:

- **`mediapulse_base`** owns the `staging → intermediate → marts` layering for `news`, `podcasts`, `streaming`, and `ads`. This is the **producer project**: most of the raw-data modelling work lives here, and it already has a working (albeit imperfect) layer for every domain.
- **`mediapulse_analytics`** is a second project. It declares `mediapulse_base` as a project dependency and consumes its `public`-access models. It also owns two fully self-contained domains of its own - an advertiser **CRM** domain and a **StreamView legacy-migration** domain - that read directly from raw sources and don't depend on `mediapulse_base` at all.

Both projects already have working models end to end. Some models carry deliberate gaps and rough edges for you to find and reason about as part of your group's exercises. See `mediapulse_base/README.md` and `mediapulse_analytics/README.md` for each project's own structure, and your group's overview page for what you'll specifically be doing with them.

---

## The business

| Platform | What it does | Raw schema | Owning project |
|----------|-------------|------------|----------------|
| **StreamVault** | Subscription streaming service - films, series, live sport. Internally called PulseStream. | `streaming` | `mediapulse_base` |
| **NewsNow** | Digital news outlet - articles, authors, page views | `news` | `mediapulse_base` |
| **PodcastHub** | Podcast network - shows, episodes, listener events | `podcasts` | `mediapulse_base` |
| **AdConnect** | Programmatic ad platform - campaigns, impressions, spend | `ads` | `mediapulse_base` |
| **SignalDesk** | Third-party CRM used by AdConnect's ad sales org - advertiser accounts, contracts, sales touchpoints | `crm` | `mediapulse_analytics` |
| **StreamView** | StreamVault's predecessor, decommissioned in 2025 - archived catalog, subscriber, and playback data | `streamview_legacy` | `mediapulse_analytics` |

---

## Raw source tables

Six raw schemas hold key data for the company, split across the two projects:

- Read by `mediapulse_base`: `streaming`, `news`, `podcasts`, `ads`
- Read by `mediapulse_analytics` (self-contained, no dependency on `mediapulse_base` for these): `crm`, `streamview_legacy`

- `streaming` (PulseStream, the current platform - table names don't match the schema name, that's intentional, not a typo)

    | Table | Key columns |
    |-------|-------------|
    | `content_ctlg` | `content_id`, `title`, `genre`, `ctnt_type`, `release_date`, `runtime_minutes` |
    | `subscriptions_lifecycle_rec` | `subscription_id`, `user_id`, `plan_type`, `status`, `start_date`, `start_time`, `end_date`, `end_time`, `monthly_fee_cents`, `updated_at` |
    | `usr_watch_events_log` | `event_id`, `user_id`, `content_id`, `watched_at`, `watch_duration_seconds`, `device_type`, `batched_at` |

- `news`

    | Table | Key columns |
    |-------|-------------|
    | `articles` | `article_id`, `title`, `author_id`, `category`, `published_at`, `updated_at`, `status`, `word_count`, plus five `score_*` reader-survey columns (`score_relevance`, `score_clarity`, `score_bias`, `score_trust`, `score_engagement`), each with a matching `num_responses_*` count |
    | `authors` | `author_id`, `name`, `email`, `joined_at` |
    | `page_views` (physical table is `views`) | `view_id`, `article_id`, `user_id`, `viewed_at`, `referrer_source` |

- `podcasts`

    | Table | Key columns |
    |-------|-------------|
    | `shows` | `show_id`, `show_name`, `host_name`, `category`, `launched_at` |
    | `episodes` | `episode_id`, `show_id`, `title`, `published_at`, `duration_seconds`, `episode_season`, `category` |
    | `listens` | `listen_id`, `episode_id`, `user_id`, `listened_at`, `listen_duration_seconds`, `platform_id` |

- `ads` (staged by reading the raw table names directly, not through a `source()` block)

    | Table | Key columns |
    |-------|-------------|
    | `campaigns` | `campaign_id`, `advertiser_id`, `campaign_name`, `campaign_type`, `start_date`, `end_date`, `budget_cents` |
    | `impressions` | `impression_id`, `campaign_id`, `content_id`, `impression_date`, `impressions_count`, `clicks` |
    | `spend` | `spend_id`, `campaign_id`, `spend_date`, `spend_cents`, `platform_fee_cents` |

- `crm` (SignalDesk export, `mediapulse_analytics`)

    | Table | Key columns |
    |-------|-------------|
    | `sales_reps` | `rep_id`, `rep_name`, `region`, `hire_date` |
    | `advertiser_accounts` | `advertiser_id`, `advertiser_name`, `industry`, `sales_rep_id`, `contract_tier`, `account_status`, `signed_at` |
    | `contracts` | `contract_id`, `advertiser_id`, `contract_value_cents`, `start_date`, `end_date`, `renewal_status` |
    | `touchpoints` | `touchpoint_id`, `advertiser_id`, `rep_id`, `touchpoint_type`, `occurred_at`, `notes` |

- `streamview_legacy` (archived StreamView data, `mediapulse_analytics`)

    | Table | Key columns |
    |-------|-------------|
    | `media_catalog_archive` | `media_id`, `media_title`, `category`, `media_format`, `release_dt`, `duration_min` |
    | `acct_subs_archive` | `subscriber_ref`, `tier`, `account_status`, `start_dt`, `start_tm`, `end_dt`, `end_tm` |
    | `playback_heartbeats` | `ping_id`, `subscriber_ref`, `media_id`, `ping_date`, `ping_time`, `playback_position_seconds`, `device_code` |


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

