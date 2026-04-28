# dbt@scale - Workshop Student Pack

This repo contains everything needed to run or adapt the **dbt@scale** workshop: the participant-facing guide site and the dbt project participants work on.

> **Contact:** Lucy Sheppard (lucy.sheppard@xebia.com) for access to the project in dbt platform or for any questions about adapting this material.

---

## Overview

A two-day hands-on dbt workshop built for one client. Participants work in four skill-levelled groups through a shared fictional data platform called **MediaPulse** - a media conglomerate with news, podcasts, streaming, and advertising domains.

The material is designed to be reusable and adapted for future clients.

The student workbook is hosted here: 
- GitHub Pages: [godatadriven.github.io/dbt-at-scale/](https://godatadriven.github.io/academy-dbt-at-scale/)
- CloudFlare (public): [academy-dbt-at-scale.pages.dev](https://academy-dbt-at-scale.pages.dev/)

---

## Repository structure

```
.
├── docs/                        # MkDocs source - the participant-facing guide
│   ├── index.md                 # Welcome page
│   ├── agenda.md
│   ├── mediapulse/              # Shared project context (overview + ERD)
│   ├── group1/                  # Intermediate: sources, testing, macros
│   │   ├── level1/checklist.md
│   │   └── level2/checklist.md
│   ├── group2/                  # Advanced I: bug fixing, seeds, snapshots
│   │   ├── level1/checklist.md
│   │   └── level2/checklist.md
│   ├── group3/                  # Advanced II: incremental models, revenue analytics
│   │   ├── level1/checklist.md
│   │   └── level2/checklist.md
│   └── group4/                  # Power users: evaluator, expectations, CI/CD
│       ├── level1/checklist.md
│       └── level2/checklist.md
├── mediapulse/                  # The dbt project participants work on
│   ├── models/
│   │   ├── staging/             # news, podcasts, ads staging models
│   │   └── marts/               # content_performance, revenue_by_content
│   ├── seeds/                   # Raw source data (CSV) - replaces a real ingestion pipeline
│   ├── snapshots/               # (empty - participants write these)
│   ├── tests/                   # (empty - participants write these)
│   ├── macros/                  # generate_schema_name override
│   ├── dbt_project.yml
│   └── packages.yml
├── mkdocs.yml                   # Site config (theme, nav, password)
├── requirements.txt             # Python deps for the docs site
└── netlify.toml                 # Netlify build config
```

---

## The dbt platform

Participants work in **dbt Cloud**. Each participant needs a dbt Cloud account with access to the MediaPulse project and the shared Snowflake environment.

**Snowflake login details**: We use username + password to access the Snowflake account. 

**dbt Cloud login:** https://xi030.us1.dbt.com/enterprise-login/xebiadatadbt/

Contact Lucy (lucy.sheppard@xebia.com) to get access to the dbt Cloud account and Snowflake for this workshop.

### How the project is set up in dbt Cloud

- The `mediapulse/` folder in this repo is connected as the dbt project root.
- Participants do **not** need to run dbt seed. This is done ahead of the session.
- Each group works in their own target schema (e.g. `dbt_lsheppard`) so they don't overwrite each other.
<!-- - The `generate_schema_name` macro override (`mediapulse/macros/generate_schema_name.sql`) ensures seeds land in exact schema names (`news`, `podcasts`, `streaming`, `ads`) rather than dbt's default prefixed names. -->

### Seed tables

Seeds simulate raw source data. Each CSV maps to a schema and table:

| CSV file | Snowflake target |
|----------|-----------------|
| `news__articles.csv` | `news.articles` |
| `news__articles_updated.csv` | `news.articles_updated` |
| `news__authors.csv` | `news.authors` |
| `news__page_views.csv` | `news.views` |
| `podcasts__shows.csv` | `podcasts.shows` |
| `podcasts__episodes.csv` | `podcasts.episodes` |
| `podcasts__episodes_updated.csv` | `podcasts.episodes_updated` |
| `podcasts__listens.csv` | `podcasts.listens` |
| `streaming__content_catalog.csv` | `streaming.content_catalog` |
| `streaming__subscriptions.csv` | `streaming.subscriptions` |
| `streaming__watch_events.csv` | `streaming.watch_events` |
| `ads__campaigns.csv` | `ads.campaigns` |
| `ads__impressions.csv` | `ads.impressions` |
| `ads__spend.csv` | `ads.spend` |

The `_updated` variants (`articles_updated`, `episodes_updated`) are used in the Group 2 snapshot exercises - they simulate what the source table looks like after upstream changes, to demonstrate SCD Type 2 behaviour.

### Intentional bugs

Several models contain deliberate bugs for participants to find and fix:

| Model | Bug |
|-------|-----|
| `stg_news__articles.sql` | No deduplication - `news.articles` has duplicate `article_id` rows |
| `stg_podcasts__episodes.sql` | References column `episode_name` which doesn't exist (should be `title`) |
| `marts/content/content_performance.sql` | INNER JOINs articles to episodes on category - produces a cross-product fan-out |
| `marts/revenue/revenue_by_content.sql` | Aggregates at `campaign_id` grain, not `content_id` - wrong for a "by content" mart |

Raw data quality issues (for testing exercises):
- `streaming.subscriptions`: mixed casing on `plan_type` and `status` columns
- `streaming.watch_events`: mixed casing on `device_type`
- `streaming.content_catalog`: mixed casing on `genre`
- `news.articles`: duplicate rows per `article_id` (most recent `updated_at` is the canonical version)

---

## Running the guide site locally

```bash
pip install -r requirements.txt
mkdocs serve
```

Open `http://localhost:8000`. The site is password-protected - the current password is set in `mkdocs.yml` under `plugins.encryptcontent.global_password`.

> **Before sharing with participants**, uncomment the `global_password` line in `mkdocs.yml` and set it to your chosen password. It is currently commented out, meaning the site is unprotected.

---

## Deploying the site

The site deploys automatically to Netlify on push to the main branch. Build config is in `netlify.toml`.

If you need to deploy to a new Netlify site, connect this repo and use:
- **Build command:** `pip install -r requirements.txt && mkdocs build`
- **Publish directory:** `site`
- **Python version:** 3.11

---

## Adapting this for a new client

1. **Update the branding** - replace `docs/images/mediapulse_logo_small.svg` with the client's logo and update `site_name` / `site_description` in `mkdocs.yml`.
2. **Update the agenda** - edit `docs/agenda.md` with the new schedule, talk titles, and presenter names.
3. **Update the welcome page** - edit `docs/index.md` to reflect the host organisation.
4. **Set a new password** - uncomment and update `global_password` in `mkdocs.yml`.
5. **Adjust skill levels** - the four-group structure and level1/level2 split can be compressed to fewer groups or expanded. Each group's checklist is a standalone markdown file.
6. **Seed data** - the CSVs in `mediapulse/seeds/` can be replaced or extended for a different domain. Keep the `_updated` variants for snapshot exercises.
7. **Connect to the client's dbt Cloud** - update the dbt Cloud project connection and target Snowflake credentials. Each participant needs their own dev target schema.

---

## Tech stack

| Layer | Tool |
|-------|------|
| Guide site | MkDocs + Material theme |
| Site encryption | mkdocs-encryptcontent-plugin |
| Hosting | Netlify |
| dbt project | dbt Core (via dbt Cloud) |
| Warehouse | Snowflake |
| Packages used | `dbt_utils`, `codegen`, `dbt_project_evaluator`, `dbt_expectations` |

