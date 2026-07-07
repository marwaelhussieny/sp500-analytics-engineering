# S&P 500 Historical Market Analytics

A pure analytics-engineering project: dbt models running on DuckDB, no
orchestrator, no external warehouse — because the dataset (monthly S&P 500
data since 1871, ~1,900 rows) doesn't need one. Visualized with
[Evidence](https://evidence.dev), a BI-as-code tool that compiles markdown +
SQL into a static dashboard site.

Built as a modernized take on a classic "stock market dbt" practice project:
same spirit (dbt transformations over financial time-series data), but with
a real, historically-grounded dataset and analysis worth showing a hiring
manager, rather than a toy transformation.

## Why this project, and why this stack

Project 1 (COVID-19 pipeline) already demonstrates Airflow + Postgres
orchestration. This project deliberately does **not** repeat that — it's
built to show the other half of the data engineering job market:
analytics engineering, where the job is almost entirely "write correct,
tested SQL transformations in dbt," not orchestrate infrastructure.

- **DuckDB, not Postgres/Snowflake.** ~1,900 rows doesn't need a warehouse
  cluster. Using one anyway would be over-engineering, and a competent
  analytics engineer should right-size infrastructure to data volume.
- **dbt seed, not a Python ingestion script.** The raw dataset is small,
  static, and versionable — exactly what dbt seeds are for. Not every
  project needs a custom extractor.
- **Evidence, not Streamlit.** Evidence is markdown + SQL that compiles to a
  static site — a different (and increasingly common) BI paradigm from
  Streamlit's Python-app model. Showing both across the portfolio
  demonstrates range.

## Data quality notes (handled explicitly, not glossed over)

The source dataset has two real quirks, both flagged rather than silently
handled:

- **`is_price_only_row`** — from 2023-07 onward, the series is
  auto-extended using only the FRED index price. Dividend, earnings, CPI,
  and PE10 are populated as `0`, not `NULL`, for these rows upstream. The
  staging model flags them so downstream models don't mistake `0` for a
  real value.
- **`is_pe10_unavailable`** — Shiller's CAPE ratio (`PE10`) requires 10
  years of trailing real earnings, which doesn't exist for the first ~120
  months of the series (1871–1880). Also flagged, for the same reason.

## Architecture

```
seeds/sp500_shiller_raw.csv          (raw Shiller dataset, dbt seed)
        │  dbt seed
        ▼
staging.stg_sp500_monthly            (typed, flagged for data quirks)
        │
        ├─▶ intermediate.int_sp500_returns     (MoM / trailing-12mo returns)
        └─▶ intermediate.int_sp500_drawdowns   (running peak, drawdown %)
        │
        ▼
marts.fct_sp500_monthly              (one row per month: price/returns/drawdown/valuation)
        │
        ├─▶ marts.mart_valuation_quintiles   (CAPE quintile vs. forward return)
        └─▶ marts.mart_decade_summary        (decade rollups)
        │
        ▼
Evidence dashboard (reads marts only)
```

## Verified results (from a real dbt run against the real dataset)

- 6 models, 11 dbt tests — all passing
- Worst drawdown ever recorded: **-84.8%**, June 1932 (Great Depression) —
  matches the historical record
- Valuation quintile analysis shows the cheapest-valuation months
  (1930s-era) followed by continued declines before the recovery — a real
  finding, not a smoothed-over "buy low" story

## Running it

```bash
# 1. Build the dbt models (uses DuckDB, no external database needed)
cd dbt_project
DBT_PROFILES_DIR=. dbt seed
DBT_PROFILES_DIR=. dbt run
DBT_PROFILES_DIR=. dbt test

# 2. Copy the built database into the Evidence project and launch the dashboard
cd ..
./scripts/refresh.sh
cd evidence
npm install --legacy-peer-deps
npm run sources
npm run dev
```

Dashboard runs at http://localhost:3000.

> **Note on `npm install`:** the Evidence template ships with connector
> packages for every supported warehouse (BigQuery, Snowflake, Postgres,
> etc.) via `@evidence-dev/sqlite`, which requires compiling a native
> `sqlite3` binding. This repo's `package.json` and `evidence.config.yaml`
> are already trimmed to only the DuckDB connector to avoid that build
> entirely — if you add other connectors back, use `--legacy-peer-deps` on
> install.

## Running dbt tests only (CI does this)

```bash
cd dbt_project
DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test
```

## Project structure

```
.
├── dbt_project/
│   ├── seeds/sp500_shiller_raw.csv
│   ├── models/staging/       # typed + flagged raw data
│   ├── models/intermediate/  # returns, drawdowns
│   └── models/marts/         # fact table + 2 analytical marts
├── evidence/
│   ├── pages/index.md        # the dashboard
│   └── sources/sp500/        # DuckDB connection + source queries
├── scripts/refresh.sh        # rebuild dbt -> sync into Evidence
└── .github/workflows/ci.yml  # dbt build+test, then Evidence build
```

## Data source

[datasets/s-and-p-500](https://github.com/datasets/s-and-p-500) — a tidied
CSV of Robert Shiller's dataset, licensed under the Open Data Commons Public
Domain Dedication and License (PDDL).
