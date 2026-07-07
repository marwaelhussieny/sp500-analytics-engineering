#!/usr/bin/env bash
# Rebuilds the dbt project and copies the resulting DuckDB file into the
# Evidence project so the dashboard reflects the latest models.
set -euo pipefail

cd "$(dirname "$0")/../dbt_project"
export DBT_PROFILES_DIR=.

dbt seed
dbt run
dbt test

cp sp500.duckdb ../evidence/sources/sp500/sp500.duckdb
echo "Done. Run 'cd evidence && npm run dev' to view the dashboard."
