# Exercise: dbt Mesh

## What is dbt Mesh?

dbt Mesh is an architectural pattern for splitting a large monolithic dbt project into multiple smaller, independently deployable projects that reference each other using **cross-project refs**.

Each project owns a slice of the data platform. Projects declare which models are `public` (available to other projects), which are `protected` (visible within the same group), and which are `private` (internal implementation detail).

📖 [dbt Mesh overview](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-1-intro)
📖 [Cross-project references](https://docs.getdbt.com/docs/collaborate/govern/project-dependencies)
📖 [Model access](https://docs.getdbt.com/docs/collaborate/govern/model-access)
📖 [Model versions](https://docs.getdbt.com/docs/collaborate/govern/model-versions)

---

## The MediaPulse use case

MediaPulse has (at least) four distinct domains:

| Domain | What it owns |
|---|---|
| Editorial | Articles, authors, news staging models |
| Podcast | Episodes, listen events, podcast staging models |
| Ads | Campaigns, impressions, spend staging models |
| Platform / Revenue | Cross-domain attribution, revenue mart, content performance |

The Platform team needs data from all three other domains. In a monolith, they just `ref()` whatever they need. In a Mesh architecture, each domain project controls what it exposes.

---

## Your task

### 1. Design the split (no code required first)

Draw the dependency graph for a Mesh split of MediaPulse:

- Which models in each domain project should be `public`? (Hint: the ones other projects `ref()`.)
- Which should be `protected` or `private`?
- What happens to `int_campaign_content_spend_allocation` — which project owns it?
- Where does `fct_ad_revenue` live?

Think about the ownership model: who should be allowed to break the Editorial → Platform contract by changing a `public` model?

### 2. Add model access to existing models

In the current monolith, add access controls to practice the syntax. In `_ads__models.yml`:

```yaml
models:
  - name: stg_ads__campaigns
    access: public
    config:
      contract:
        enforced: true
```

📖 [Model contracts](https://docs.getdbt.com/docs/collaborate/govern/model-contracts)

What does enforcing a contract mean? What happens if you change a column type in a contracted model?

### 3. Define a model version

Model versions let you introduce breaking changes without immediately breaking downstream consumers. Version an existing model:

```yaml
models:
  - name: stg_ads__campaigns
    latest_version: 2
    versions:
      - v: 1
        defined_in: stg_ads__campaigns_v1  # old model file
      - v: 2
        # uses the default stg_ads__campaigns.sql
```

Downstream consumers can pin to `ref('stg_ads__campaigns', v=1)` while you migrate them to v2.

When would you use versioning vs. just making the change and updating all refs?

### 4. Hard cases

- **Circular dependencies**: what happens if Platform depends on Ads, and Ads wants to use a Platform metric? How do you break the cycle?
- **Schema drift**: the Ads team renames `spend_cents` to `spend_millicents`. The contract enforces this — who gets paged?
- **Cross-project testing**: how do you test a `relationships` constraint across project boundaries?
- **Governance**: who has the right to make a model `public`? Should this be a PR review process, a CI check, or both?

---

## Discussion questions

- When does a monolith become a Mesh? What's the forcing function?
- What's the minimum team size / project size where Mesh adds value vs. adds overhead?
- How would you handle a `public` model that a downstream project depends on but the owning team wants to deprecate?
