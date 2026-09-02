#!/bin/bash

# Catcoin PoE Backend Deployment Script
# API hostname: configure in DNS (do not commit static server IPs).

set -e
cd "$(dirname "$0")"

echo "🚀 Catcoin PoE Backend Deployment"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo -e "${RED}ERROR: .env.production file not found!${NC}"
    echo "Please copy .env.production.example and configure it:"
    echo "  cp .env.production.example .env.production"
    echo "  nano .env.production"
    exit 1
fi

# Load environment variables
export $(cat .env.production | grep -v '^#' | xargs)

# docker-compose.prod.yml uses env_file: .env — keep it in sync with production secrets.
cp -f .env.production .env

PUBLIC_API_BASE="${PUBLIC_API_BASE:-https://poe.catcoin.in}"
PUBLIC_API_BASE="${PUBLIC_API_BASE%/}"

# Create logs directory if not exists
mkdir -p logs
chmod 777 logs

echo -e "${YELLOW}Step 1: Stopping existing containers...${NC}"
docker compose -f docker-compose.prod.yml down

echo -e "${YELLOW}Step 2: Building backend_blue image...${NC}"
docker compose -f docker-compose.prod.yml build --no-cache backend_blue

echo -e "${YELLOW}Step 3: Starting database...${NC}"
docker compose -f docker-compose.prod.yml up -d postgres

echo -e "${YELLOW}Step 4: Waiting for database to be ready...${NC}"
sleep 10

echo -e "${YELLOW}Step 5: Database migrations (Alembic + run_all_migrations.py)...${NC}"
chmod +x apply_db_migrations.sh
# Prod compose has backend_blue / backend_green only; default to blue for this legacy script.
COMPOSE_FILE=docker-compose.prod.yml MIGRATION_SERVICE=backend_blue ./apply_db_migrations.sh

echo -e "${YELLOW}Step 6: Creating root admin user...${NC}"
docker compose -f docker-compose.prod.yml run --rm backend_blue python create_root_user.py

echo -e "${YELLOW}Step 7: Seeding missions...${NC}"
docker compose -f docker-compose.prod.yml run --rm backend_blue python seed_missions.py

echo -e "${YELLOW}Step 8: Starting all services...${NC}"
docker compose -f docker-compose.prod.yml up -d

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Services status:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "🌐 Backend API: ${PUBLIC_API_BASE}"
echo "📖 API Docs: ${PUBLIC_API_BASE}/docs"
echo ""
echo "To view logs:"
echo "  docker compose -f docker-compose.prod.yml logs -f backend_blue"
echo ""
echo "To stop services:"
echo "  docker compose -f docker-compose.prod.yml down"
