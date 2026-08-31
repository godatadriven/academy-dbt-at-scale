# Group 3 - Part 1 Instructor Notes

*Power Users · topics 1.1–1.5 · pair with the Google Slide deck for each topic*

**Frame:** audience is assumed fluent (skill level, not shared repo history - see below). Day 1 builds forward: onboard → hit real CRM volatility + a planted fee bug → build a genuinely new consolidated streaming model from legacy + current data → govern it and CRM for a new consumer.

**Setup:** `set_up_project` must already be seeded. Students need dbt Cloud access to both projects + Snowflake SSO. Branch: `dpg/<your_name>/day1`.

**Watch out:** the business overview calls the current platform **StreamVault**; the `streaming` source YAML calls it **PulseStream**. Unreconciled - pick one. The legacy platform is consistently **StreamView** everywhere.

**"Assumed comfortable" ≠ shared history:** Groups 1/2/3 are independent tracks over the *same* starting repo, not one cohort's progress. `dim_campaigns`'s access bug (fixed for real in 2.1) is unfixed at the start of this track too.

**Instructor eyes only:** `set_up_project/analyses/staff_members.ipynb` is the answer-key notebook for 1.2's fee test - it shows the exact generated fee per plan/staff bucket. Never open or screen-share it during 1.2.

---

### 1.1 - dbt Catalog & Onboarding
- Grain mismatch: legacy `playback_heartbeats` = one row per ~1-minute ping; current `usr_watch_events_log` = one row per *completed* event with a duration. Not the same shape - legacy needs aggregating up, not the reverse.
- Legacy subscriptions (`acct_subs_archive`) have **no monetary field at all**, only `tier` - a real, permanent asymmetry, not a gap to explain away.
- `is_mapped = false` (via `map_streaming_legacy_fields`) is expected - migration is deliberately incomplete. Keep the legacy id and flag it; don't drop the row.
- Step 4 flags `int_adv_rep_touchpoint_cumcounts`'s `has_real_text` regex logic as a missing-unit-test candidate - plan only, built for real in 2.5.

### 1.2 - Testing Coverage
- Exactly 4 `accepted_values` tests on CRM data. The SignalDesk vendor note in `mediapulse_analytics/README.md` maps a distinct correct tactic to each:

  | Field | What's coming | Correct tactic |
  |---|---|---|
  | `contract_tier` | Casing drift ("Gold" vs "gold"), no clean timeline | Fix in staging SQL - can't pad against infinite casing |
  | `account_status` | `paused` → `flagged_for_review`, two known stages | Pad the list proactively |
  | `renewal_status` | `pending_renewal` → `in_negotiation`, same timeline | Pad the list proactively |
  | `touchpoint_type` | Unnamed values, unknown timing | `severity: warn` |

  "Most at risk" answer: **`contract_tier`** (hard error, no announced gate) - accept a well-argued case for the other two.
- Fee test answer key: basic 599 / staff 525 · standard 999 / staff 875 · premium 1499 / staff 1312. Staff rate = price − **floor**(price × 0.125), not a rounded 12.5% off - a naive test will be a cent off. There are **3 planted non-staff rows** sitting at the standard/875 staff price; a correct test finds exactly those 3. Zero violations = the test isn't checking the right thing.

### 1.3 - dbt Mesh
- Real modeling centerpiece - students query base's current streaming data cross-project, compare it to StreamView, then actually **build** `fct_all_streaming_events` (not just design it), with an `is_legacy` flag.
- The legacy/current overlap-window question needs a live `min`/`max` query on `ping_date`/`watched_at` - don't quote a remembered number, the seed dates have shifted.
- Reconciling ids: prefer the current-platform id when mapped, else carry the legacy id forward with `is_legacy = true` and leave the current-id column null. Silently dropping unmapped rows destroys the exact signal the domain exists to preserve.
- Versioning extension answer: a version-pinned consumer keeps resolving the old contract until they deliberately bump - insulated, not exposed.

### 1.4 - Model Governance with dbt Mesh
- Order matters: **contract first** (every column typed, confirmed `table`/`view`), then **access** (`public` only on each domain's front door, `private` upstream), then **groups** (2 groups, 1 owner each, every model in exactly one), then **versioning**.
- Real breaking change: split `occurred_at` into `occurred_at_date`/`occurred_at_time` on `fct_crm_touchpoints`. `v1` keeps the original, `v2` has the split, `latest_version: 1` stays, realistic `deprecation_date`.
- Proof it's wired right: `dbt run --select fct_crm_touchpoints` builds both versions; `...,version:latest` builds only `v1`.
- Contrast with Group 2: there, students govern someone else's finished model. Here, they govern the `all_streaming` domain they built themselves two hours earlier - the "is this actually stable enough" call is real.

### 1.5 - Homework & Wrap
- No new content - checklist/PR rubric for 1.2–1.4, plus a doc/test health check (not 100% coverage - judgment on what's worth fixing is part of the grade).
- No equivalent wrap page exists for Part 2 - each 2.x topic stands on its own deliverable.
