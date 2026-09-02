#!/usr/bin/env bash
# Canonical DB upgrade path for this repo (local + production).
#   1) alembic upgrade head
#   2) python run_all_migrations.py  (SQL scripts, enums, seeds, admin_config from .env — see MIGRATIONS)
#
# When you add schema: prefer new Alembic revisions under alembic/versions/ and/or new
# scripts in run_all_migrations.py — do not rely on main.py startup alone for deploys.
#
# Usage (from cat_poe_backend/):
#   ./apply_db_migrations.sh
#       Uses: docker compose … run --rm backend  (docker-compose.yml)
#
#   COMPOSE_FILE=docker-compose.prod.yml MIGRATION_SERVICE=backend_green ./apply_db_migrations.sh
#       Uses prod compose and the given backend service (mirror_deploy sets these).
#
set -euo pipefail
cd "$(dirname "$0")"

COMPOSE=(docker compose)
if [ -n "${COMPOSE_FILE:-}" ]; then
  COMPOSE+=(-f "$COMPOSE_FILE")
fi
SVC="${MIGRATION_SERVICE:-backend}"

echo "==> [apply_db_migrations] alembic upgrade head (compose + service: ${COMPOSE[*]} / $SVC)..."
"${COMPOSE[@]}" run --rm "$SVC" alembic upgrade head

echo "==> [apply_db_migrations] python run_all_migrations.py ..."
"${COMPOSE[@]}" run --rm "$SVC" python run_all_migrations.py

echo "==> [apply_db_migrations] done."
