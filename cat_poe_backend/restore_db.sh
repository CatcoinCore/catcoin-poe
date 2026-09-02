#!/bin/bash
# Restore database (uses DB_PASSWORD from environment or .env)

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

: "${DB_PASSWORD:?Set DB_PASSWORD (e.g. in .env) to match Postgres}"

if [ -z "${1:-}" ]; then
    echo "Usage: ./restore_db.sh <backup_file>"
    echo "Available backups:"
    ls -1 ./backups/*.sql 2>/dev/null || echo "(none)"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found!"
    exit 1
fi

echo "Restoring database from $BACKUP_FILE..."

echo "Dropping and recreating database..."
docker compose -f docker-compose.prod.yml exec -T postgres sh -c "
 export PGPASSWORD=\"$DB_PASSWORD\"
 echo \"Dropping existing database catcoin_poe...\"
 psql -U catpoe -d template1 -c \"DROP DATABASE IF EXISTS \\\"catcoin_poe\\\" WITH (FORCE);\"

 echo \"Creating new database catcoin_poe...\"
 psql -U catpoe -d template1 -c \"CREATE DATABASE \\\"catcoin_poe\\\";\"
"

echo "Importing data..."
if ! cat "$BACKUP_FILE" | docker compose -f docker-compose.prod.yml exec -T postgres sh -c "
 export PGPASSWORD=\"$DB_PASSWORD\"
 psql -U catpoe -d catcoin_poe
"; then
    echo "Restore failed!"
    exit 1
fi

echo "Restore successful!"
