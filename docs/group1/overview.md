# Group 1 - Intermediate

## Your slice of MediaPulse

The `mediapulse_base` project already exists, with a working `staging → intermediate → marts` layering across `podcasts` and `news`. Your job across today is to work *with* that project the way a new hire would: understand it via tooling before touching code, refresh your modeling fundamentals against real models, close real test gaps, eliminate real repetition with macros, and try dbt's AI assistant on real work.

Everything in Part 1 and Part 2 lives in `mediapulse_base`. You won't need `mediapulse_analytics` today - that's Group 2 and Group 3's territory once dbt Mesh enters the picture.


---

## Learning objectives

By the end of today you will be able to:

- Navigate a project's lineage, test coverage, and documentation using **dbt Catalog**, without reading every file
- Explain what each layer of a `staging → intermediate → marts` project is responsible for, and argue where a piece of logic belongs
- Decide which columns genuinely need a test, write **generic**, **singular**, and `dbt_utils` tests, and configure test **severity**
- Read, and write, **Jinja macros** that remove real repetition in a project
- Build a **snapshot** with the correct change-detection strategy for a given column
- Explain what `access`, `group`, `contract`, and model **version** each do, and when to reach for each one
- Convert a model to **incremental**, justify a strategy choice, and know when a full-refresh is unavoidable
- Write clear YAML documentation and test suggestions by hand for unfamiliar code, and know where an AI assistant like dbt Wizard would help in the real world

---

## Relevant project

You'll work exclusively in `mediapulse_base`:

- `models/staging/` - news, podcasts, streaming, ads
- `models/intermediate/` - campaign spend allocation, episode listen completion
- `models/marts/` - campaigns, dates, and (by the end of today) your own snapshot and incremental additions

See the [MediaPulse overview](../mediapulse/overview.md) for the underlying business context and raw table details, and `mediapulse_base/README.md` for the project's own structure notes.
