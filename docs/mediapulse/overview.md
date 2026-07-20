# MediaPulse - Project Overview

**MediaPulse** is a fictional media company that manages four distinct platforms. All four feed data into a dbt platform that your group will work on today.

---

## The business

| Platform | What it does | Raw schema |
|----------|-------------|------------|
| **StreamVault** | Subscription streaming service: films, series, live sport | `streaming` |
| **NewsNow** | Digital news outlet: articles, authors, page views | `news` |
| **PodcastHub** | Podcast network: shows, episodes, listener events | `podcasts` |
| **AdConnect** | Programmatic ad platform: campaigns, impressions, spend | `ads` |

---

## Two connected dbt projects

The MediaPulse analytics platform is split into two dbt projects that depend on each other.

| Project | What it owns | Who works here |
|---------|-------------|----------------|
| [mediapulse_platform](platform-overview.md) | All domain staging models, intermediate calculations, shared macros and seeds | Groups 1 and 2 primarily; Groups 3 and 4 audit and harden it |
| [mediapulse_analytics](analytics-overview.md) | Business marts, commission seeds, campaign snapshots, singular tests | Groups 3 and 4 primarily |

This separation mirrors how real analytics engineering teams work at scale. The platform team controls the trusted data contract boundary. The analytics team builds on top of that foundation and can iterate independently.

See the individual project pages for structure diagrams, getting started steps, and which models belong to each group's exercise.

---

## Why two projects?

When a single dbt project grows large enough, different teams start stepping on each other's changes, CI runs take too long, and a bad mart model can delay a platform job that other teams depend on.

Splitting into two projects lets each team:

- Deploy on their own schedule without waiting for unrelated work
- Expose only what downstream projects need, through versioned, contracted public models
- Limit the blast radius of a change: a bug in an analytics mart cannot break a platform staging run

Groups 3 and 4 wire the two projects together using dbt mesh and cross-project refs. That exercise is the practical payoff of the split.

---

## Raw source tables

There are four raw schemas. See the [Data ERD](data-erd.md) for the full entity relationship diagram.

- `streaming`: `watch_events`, `subscriptions`, `content_catalog`
- `news`: `articles`, `authors`, `page_views`
- `podcasts`: `shows`, `episodes`, `listens`
- `ads`: `campaigns`, `impressions`, `spend`
