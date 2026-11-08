#!/usr/bin/env bash
# Rebuild ahamove_a2 from numbered SQL scripts (run from A2/ repo root).
# Usage:  ./sql/reset_demo.sh
#         MYSQL_PWD=secret ./sql/reset_demo.sh   # optional, avoids prompt
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MYSQL=(mysql -u "${MYSQL_USER:-root}")
if [[ -n "${MYSQL_PWD:-}" ]]; then
  :
elif [[ -n "${MYSQL_PASSWORD:-}" ]]; then
  export MYSQL_PWD="$MYSQL_PASSWORD"
fi

echo "==> Recreating database…"
"${MYSQL[@]}" -p < sql/reset_demo.sql

echo "==> Loading 01_schema.sql…"
"${MYSQL[@]}" -p ahamove_a2 < sql/01_schema.sql

echo "==> Loading 02_seed.sql…"
"${MYSQL[@]}" -p ahamove_a2 < sql/02_seed.sql

echo "==> Loading 03_programmability.sql…"
"${MYSQL[@]}" -p ahamove_a2 < sql/03_programmability.sql

echo "==> Done. Tables:"
"${MYSQL[@]}" -p -e "USE ahamove_a2; SHOW TABLES;"
