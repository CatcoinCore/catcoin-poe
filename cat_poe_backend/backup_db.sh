#!/bin/bash
# Backup database (uses DB_PASSWORD from environment or .env via `set -a; source .env`)

set -euo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

: "${DB_PASSWORD:?Set DB_PASSWORD (e.g. in .env) to match Postgres}"

mkdir -p ./backups
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="./backups/catcoin_backup_$TIMESTAMP.sql"

echo "Starting database backup to $BACKUP_FILE..."

docker compose -f docker-compose.prod.yml exec -T postgres sh -c \
  "export PGPASSWORD=\"$DB_PASSWORD\"; pg_dump -U catpoe catcoin_poe" > "$BACKUP_FILE"

if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    echo "Backup successful! File saved to: $BACKUP_FILE"
else
    echo "Backup failed!"
    rm -f "$BACKUP_FILE"
    exit 1
fi
