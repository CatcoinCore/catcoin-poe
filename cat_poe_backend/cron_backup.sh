#!/bin/sh
# Automated Database Backup Script (Internal to Docker)

# Configuration from environment variables
DB_HOST=${DB_HOST:-postgres}
DB_USER=${DB_USER:-postgres}
DB_NAME=${DB_NAME:-catcoin_poe}
BACKUP_DIR="/app/backups"
KEEP_BACKUPS=168 # 7 days of hourly backups

mkdir -p "$BACKUP_DIR"

echo "🚀 Starting automated database backup service..."
echo "📅 Frequency: Every 1 hour"
echo "📦 Storage: $BACKUP_DIR"

while true; do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

    echo "[$(date)] Starting backup of $DB_NAME to $BACKUP_FILE..."

    # Perform the backup using pg_dump
    # Note: PGPASSWORD is used for authentication
    if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"; then
        echo "[$(date)] ✅ Backup successful!"
        
        # Cleanup old backups (keep only KEEP_BACKUPS most recent files)
        echo "[$(date)] Cleaning up old backups (keeping last $KEEP_BACKUPS)..."
        (ls -t "$BACKUP_DIR"/db_backup_*.sql | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -f) 2>/dev/null
    else
        echo "[$(date)] ❌ Backup failed!"
        rm -f "$BACKUP_FILE"
    fi

    echo "[$(date)] Sleeping for 3600 seconds until next backup..."
    sleep 3600
done
