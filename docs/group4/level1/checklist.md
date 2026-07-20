# Group 4 - Checklist Level 1

## Multi-project Workflows: Contracts and Groups

Start here. Your first job is to add model contracts and access controls to `mediapulse_platform` so that `mediapulse_analytics` can safely consume its models.

In this level you will:

- **Define model contracts** on key staging models in the platform project
- **Apply model access controls** (`public`, `protected`, `private`) to the right models
- **Create groups** to organise models by domain ownership
- **Verify** that the contracts protect downstream consumers as expected

Work through the steps in order. Document your decisions throughout.

---

## Step 1 - Decide which models to expose publicly

- [ ] Step complete

Before writing any YAML, answer these questions as a group:

1. Which models in `mediapulse_platform` does `mediapulse_analytics` need to `ref()`? Those are your `public` candidates.
2. Which models should be visible within the platform project only (intermediate helpers, internal staging)? Those are `protected`.
3. Are there any models that should be completely internal to a specific domain group? Those are `private`.

Read the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access) before deciding.

??? tip "Hint: thinking about the access levels"
    Public models are the API surface of your project. Anyone with a dependency on your project can call `ref('mediapulse_platform', 'model_name')`. Once a model is public, changing its columns is a breaking change for all downstream consumers.

    Protected models are the default. They can be referenced within the same project but not from outside it.

    Private models are only accessible within the same group (a group is a collection of models you define in YAML). Use them for implementation details you never want other domains to depend on.

---

## Step 2 - Create groups in the platform project

- [ ] Step complete

Add a `groups:` block to a YAML file in `mediapulse_platform`. Define at least one group per source domain (news, podcasts, streaming, ads).

Read the [model access documentation](https://docs.getdbt.com/docs/mesh/govern/model-access) for the group YAML syntax.

Assign each staging model to its domain group using the `group` config key in its YAML entry.

??? tip "Hint: which file to put groups in"
    Groups can be defined in any YAML file in the project. A common pattern is to define them in a top-level `_groups.yml` file or in the relevant `_staging__models.yml` file for each domain. Assign models to groups in the same file where you document them.

---

## Step 3 - Add model contracts to public models

- [ ] Step complete

For each model you decided to make public in Step 1, add:

- `access: public` in the model YAML
- `config.contract.enforced: true`
- A `data_type` for every column (contracts require full column coverage)

Read the [model contracts documentation](https://docs.getdbt.com/docs/mesh/govern/model-contracts) for the full syntax and the list of supported data types.

!!! warning "Contracts require full column coverage"
    Every column produced by the model must be listed in the YAML with a `data_type`. Use codegen to get the full column list:

    ```bash
    dbt run-operation generate_model_yaml --args '{"model_names": ["stg_news__articles"]}'
    ```

    Then add `data_type` to each column and the `contract.enforced: true` config.

---

## Step 4 - Test that contracts enforce correctly

- [ ] Step complete

Run the contracted models:

```bash
dbt run --select stg_news__articles stg_news__authors stg_podcasts__episodes
```

If any run fails, read the error message. Contract violations produce a clear error stating which column has the wrong type or is missing.

Now try deliberately breaking a contract: change a `data_type` in the YAML to the wrong type (e.g. change `varchar` to `integer` on a string column) and re-run. What happens?

Revert your change before moving on.

---

## Step 5 - Verify the full platform build

- [ ] Step complete

```bash
dbt build --select mediapulse_platform
```

All models should pass. Fix any failures before moving to Level 2.

---

!!! success "Done?"
    You have defined model contracts and access controls in `mediapulse_platform`. The models you marked public are now safe to consume from `mediapulse_analytics`.

    Head to [Level 2](../level2/checklist.md) to wire the cross-project references and complete the dbt mesh setup!
