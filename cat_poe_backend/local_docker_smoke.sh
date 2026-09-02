#!/usr/bin/env bash
# Run DB + API with docker-compose.yml, apply migrations, hit /health.
# Use this to verify the backend before mirror_deploy / production.
#
# DB schema: same steps as mirror_deploy — ./apply_db_migrations.sh (Alembic + run_all_migrations.py).
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Building and starting postgres + backend (dev compose)..."
docker compose up -d --build

echo "==> Waiting for postgres healthy..."
until docker inspect -f '{{.State.Health.Status}}' catcoin_postgres 2>/dev/null | grep -q healthy; do
  sleep 2
done

chmod +x apply_db_migrations.sh
./apply_db_migrations.sh

echo "==> Health check..."
HOST_PORT="$(docker compose port backend 8000 2>/dev/null | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p')"
if [ -z "$HOST_PORT" ]; then
  echo "FAIL: could not read host port (is backend running?). Try: docker compose logs -f backend"
  exit 1
fi
curl -sf "http://127.0.0.1:${HOST_PORT}/health" | head -c 200 || {
  echo "FAIL: backend not responding on http://127.0.0.1:${HOST_PORT}/health"
  echo "Try: docker compose logs -f backend"
  exit 1
}
echo ""
echo "OK. API: http://127.0.0.1:${HOST_PORT}/docs"
