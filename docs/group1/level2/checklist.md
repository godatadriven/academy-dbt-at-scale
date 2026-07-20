# Group 1 - Checklist Level 2

## Seeds and Snapshots

Start on this checklist once you have completed [Level 1](../level1/checklist.md).

In this level you will apply the following skills:

- **Seeds**: version-controlled reference data loaded into the warehouse as tables
- **Snapshots**: SCD Type 2 tracking for slowly changing records

Work through the steps in order.

---

## Step 1 - Understand when to use a seed

- [ ] Step complete

Before creating a seed, answer these questions for the data you are about to load:

1. Is this data small and slow-changing (days or weeks between updates)?
2. Does it belong in version control (so every change is tracked in git)?
3. Would a source table or a YAML `vars` block be a better fit for this data?

Read the [dbt seeds documentation](https://docs.getdbt.com/docs/build/seeds) if you have not already.

---

## Step 2 - Create a device type category seed

- [ ] Step complete

The streaming team wants to group device types into categories for reporting:

```
device_type,device_category
smart tv,connected_tv
tablet,mobile
web,desktop
mobile,mobile
```

Create this file at `seeds/device_category_map.csv` in `mediapulse_platform`.

Think about:

- Where in the project should this seed land in the warehouse (which schema)?
- What column types should you declare to avoid Snowflake inferring the wrong types?

After creating the file, load it:

```bash
dbt seed --select device_category_map
```

Confirm the table exists in the warehouse and looks correct.

??? tip "Hint: seed configuration in dbt_project.yml"
    Seeds are configured in `dbt_project.yml` under a `seeds:` block. You can set a target schema and declare column types there. Read the [seeds documentation](https://docs.getdbt.com/docs/build/seeds) for the config keys.

---

## Step 3 - Use the seed in a staging model

- [ ] Step complete

Update `stg_streaming__watch_events.sql` to join to your new seed and add a `device_category` column.

Use `{{ ref('device_category_map') }}` to reference the seed. This keeps the lineage visible in the DAG.

Run and test:

```bash
dbt run --select stg_streaming__watch_events
dbt test --select stg_streaming__watch_events
```

---

## Step 4 - Understand when to use a snapshot

- [ ] Step complete

Before writing snapshot config, answer these questions:

1. Which records in the `streaming` domain could change over time after they are first created? (Think about subscriptions: a user's `plan_type` or `status` can change.)
2. Why would overwriting the current row lose valuable business information?
3. What does "SCD Type 2" mean, and how does dbt implement it?

Read the [dbt snapshots documentation](https://docs.getdbt.com/docs/build/snapshots) before writing any YAML.

??? tip "Hint: the core insight"
    `stg_streaming__subscriptions` is rebuilt from `streaming.subscriptions` on every run. If a user upgrades from `basic` to `premium`, the previous state disappears permanently. Snapshots solve this by inserting a new row for the changed record, setting `dbt_valid_to` on the old row, and leaving `dbt_valid_to` null on the new row.

    `dbt_valid_from` and `dbt_valid_to` together let you answer "what was this user's plan on date X?"

---

## Step 5 - Create a subscription snapshot

- [ ] Step complete

Create `snapshots/snap_streaming__subscriptions.yml` in `mediapulse_platform`.

The snapshot should track changes to `plan_type` and `status` on subscription records over time. Decide:

- `unique_key`: which column identifies a subscription record?
- `strategy`: does `streaming.subscriptions` have an `updated_at` column? If yes, use `timestamp`. If no, use `check` and list the columns to monitor.
- Which columns are likely to change over time, and which are essentially static?

Read the [snapshots documentation](https://docs.getdbt.com/docs/build/snapshots) for the YAML syntax.

Run the snapshot:

```bash
dbt snapshot --select snap_streaming__subscriptions
```

Query the snapshot table. What columns did dbt add? What do `dbt_valid_from`, `dbt_valid_to`, and `dbt_scd_id` mean?

---

## Step 6 - Simulate a change and re-run the snapshot

- [ ] Step complete

To see the snapshot in action without waiting for real data to change, update the source definition to point at an updated version of the seed data (your facilitator will tell you which table to use or how to simulate a change in the workshop environment).

Run:

```bash
dbt snapshot --select snap_streaming__subscriptions
```

Then query:

```sql
select * from snapshots.snap_streaming__subscriptions
where dbt_valid_to is not null
order by dbt_updated_at desc
```

You should see old rows with a `dbt_valid_to` date and new current rows with `dbt_valid_to is null`.

---

## Step 7 - BONUS: Snapshot for news articles

- [ ] Step complete

Create a second snapshot for `news.articles` tracking changes to `title`, `category`, and `status`. Use the `timestamp` strategy with `updated_at` as the marker.

Why would you want to track article title changes? Think of a business question you could only answer with this history.

---

!!! success "Done?"
    You have loaded reference data as a seed, used it in a staging model, and implemented SCD Type 2 tracking for subscription records. You can now answer questions about what was true at any point in the past.

    Head to [Level 3](../level3/checklist.md) for next-level testing: test configurations and custom generic tests!
