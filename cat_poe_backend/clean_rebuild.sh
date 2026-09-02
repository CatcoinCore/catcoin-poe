#!/bin/bash
# Master Rebuild Script

echo "WARNING: This script will backup your database, delete all containers/volumes, rebuild the backend, and restore the data."
echo "Press Ctrl+C to cancel or wait 5 seconds to proceed..."
sleep 5

# Step 1: Backup
echo "Step 1: Backing up database..."
./backup_db.sh
if [ $? -ne 0 ]; then
    echo "Backup failed! Aborting to prevent data loss."
    exit 1
fi

# Find the latest backup file
LATEST_BACKUP=$(ls -t ./backups/*.sql | head -n 1)
echo "Latest backup is: $LATEST_BACKUP"

# Step 2: Tear Down
echo "Step 2: Stopping containers and removing volumes..."
#docker compose -f docker-compose.prod.yml down -v
docker compose -f docker-compose.prod.yml down --rmi all -v
docker system prune -f

# Step 3: Rebuild
echo "Step 3: Rebuilding backend image (no cache)..."
docker compose -f docker-compose.prod.yml build --no-cache backend

# Step 4: Start Up
echo "Step 4: Starting services..."
docker compose -f docker-compose.prod.yml up -d

# Wait for Postgres to be ready
echo "Waiting for database to initialize (10 seconds)..."
sleep 10

# Step 5: Restore
echo "Step 5: Restoring database..."
./restore_db.sh "$LATEST_BACKUP"

# Step 6: Apply Migration (Fix Schema)
echo "Step 6: Applying migration script..."
docker compose -f docker-compose.prod.yml run --rm backend python update_x_credentials_schema.py

echo "=========================================="
echo "Clean rebuild and restore complete!"
echo "=========================================="
