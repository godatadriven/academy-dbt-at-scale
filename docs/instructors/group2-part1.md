# Group 2 - Part 1 Instructor Notes

*Multi-project dbt · topics 1.1–1.5 · pair with the Google Slide deck for each topic*

**Frame:** this cohort owns the streaming domain in `mediapulse_base`. `mediapulse_analytics` is their real consumer. The spine of the day: `fct_streaming_events` is `access: public` but self-admits a join fan-out - "allowed to reference" and "safe to depend on" are different claims, discovered in 1.1, fixed in 1.2, contracted in 1.4.

**Setup:** `set_up_project` must already be seeded. Students need dbt Cloud access to both projects + Snowflake SSO. Branch: `dpg/<your_name>/day1`.

**Watch out:** the business overview calls the current platform **StreamVault**; the `streaming` source YAML in `mediapulse_base` calls it **PulseStream**. Unreconciled - pick one before presenting.

---

### 1.1 - dbt Catalog & Review
- Only two models actually cross the mesh boundary today: `fct_content_performance` and `fct_ad_revenue`. All three streaming marts (`dim_content_catalog`, `dim_subscriptions`, `fct_streaming_events`) are public **and unreferenced** - "public" ≠ "used."
- `dim_campaigns`'s docs promise cross-project use but `ads/` marts default to `protected` with no override - a real, live gap. **Spot only, don't fix** (not part of this track).
- Step 4 is plan-only. It gets executed for real in 1.2 (fix) and 1.4 (contract).

### 1.2 - Advanced Testing *(longest topic - protect the time)*
- `content_type`: pad `accepted_values` with the two new values - they're *known* ahead of time, so padding beats `severity`.
- `release_date`: `not_null` scoped with `config: where:` to rows where `ctnt_type` resolved.
- `plan_type`: `dbt_utils.not_empty_string` on **staging**, not the mart (mart already lowercased).
- `int_dedupe_subscribers`: `dbt_utils.fewer_rows_than` vs. the staging model it's built from.
- **Root cause of everything:** `stg_streaming__subscriptions_lifecycle_rec` is one row per *subscription event*, not per user. `int_dedupe_subscribers` already exists and already fixes this.
- `dim_subscriptions.user_id` unique test fails → re-point at `int_dedupe_subscribers`.
- `fct_streaming_events.event_id` unique test fails → same root cause, different join. Two valid fixes, both required in the homework: (a) join `int_dedupe_subscribers` - simple, always correct row count, but loses point-in-time accuracy (every event gets the user's *most recent* subscription); (b) add a date-range join condition on `watched_at` - accurate, more SQL, breaks on overlapping/gapped subscriptions.

### 1.3 - Jinja/Macros & Custom Schema Logic
- `safe_divide(numerator, denominator, precision=4)` → 0 on zero denominator, else rounded division. Swap into `fct_ad_impressions.sql`'s `click_through_rate`.
- `generate_schema_name.sql` is currently **identical to dbt's default** (`{{ target.schema }}` with no custom schema, else `{{ target.schema }}_{{ custom_schema }}`) - the override does nothing until Step 3 adds the dev/prod branch keyed on `target.name`.
- **Answer key:** a project dependency exposes only *public models*, never code - there's no mesh mechanism to share this macro with `mediapulse_analytics`. Correct answer is "duplicate, by convention," not "share via mesh."

### 1.4 - dbt Mesh
- Step 3's team-lead message splits into two asks: real, ongoing commitment on the 3 streaming marts (legacy consolidation) vs. explicitly throwaway pokes at `ads`/`news` staging. Don't grant both the same weight.
- Add explicit model-level `access: public` to the 3 marts (currently public only via folder default) - no behavior change, just intent made real.
- Contract the 3 marts (every column typed, verified against real warehouse output).
- **Judgment call, no fixed answer:** should staging get a contract too? Grade the reasoning - the request only asked for stability on the marts; staging contracts cost you on every future source change.
- **Trap:** cross-project `ref()` resolves against `mediapulse_base`'s last successful **production** run - merging isn't enough, a prod build has to run too.
- Extension (versioning) is the first thing to make optional if the room is behind: `monthly_fee_cents` → `monthly_fee_dollars`, `v1`/`v2`, `latest_version: 1`, realistic `deprecation_date`.

### 1.5 - Homework & Wrap
- No new content - it's the checklist/PR rubric for 1.2–1.4. Don't teach it line by line; use it to grade. The fan-out bug (1.2) is the centerpiece of the PR description - make sure it isn't undersold.
- No equivalent wrap page exists for Part 2 - each 2.x topic stands on its own deliverable.
