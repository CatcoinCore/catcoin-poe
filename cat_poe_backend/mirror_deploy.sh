#!/usr/bin/env bash

# Catcoin PoE Blue-Green (Mirror) Deployment Script
# External health check and summary URLs use PUBLIC_API_BASE (set in .env.production; optional override for forks).
#
# DB schema: ./apply_db_migrations.sh (Alembic + run_all_migrations.py) — keep in sync with local_docker_smoke.sh.

set -e
cd "$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Nginx must be in State.Status=running before `docker exec` (exec fails while Restarting).
reload_nginx() {
    echo -e "${YELLOW}Ensuring nginx is up, then reloading config...${NC}"
    docker compose -f docker-compose.prod.yml up -d nginx
    local max_iter=45
    local i=0
    until [ "$(docker inspect -f '{{.State.Status}}' catcoin_nginx 2>/dev/null)" = "running" ]; do
        if [ "$i" -ge "$max_iter" ]; then
            echo -e "${RED}ERROR: catcoin_nginx did not reach state 'running'.${NC}"
            echo -e "${YELLOW}Current status: $(docker inspect -f '{{.State.Status}}' catcoin_nginx 2>/dev/null || echo 'container missing')${NC}"
            echo -e "${YELLOW}Recent nginx logs:${NC}"
            docker logs --tail 80 catcoin_nginx 2>&1 || true
            return 1
        fi
        echo -n "."
        sleep 2
        i=$((i + 1))
    done
    echo ""
    docker exec catcoin_nginx nginx -s reload
}

echo "🚀 Catcoin PoE Blue-Green Deployment"
echo "===================================="

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo -e "${RED}ERROR: .env.production file not found!${NC}"
    exit 1
fi

# Load environment variables
export $(cat .env.production | grep -v '^#' | xargs)

cp -f .env.production .env

# No trailing slash — used for curl /health and post-deploy echoes
PUBLIC_API_BASE="${PUBLIC_API_BASE:-https://poe.catcoin.in}"
PUBLIC_API_BASE="${PUBLIC_API_BASE%/}"

# Create logs directory if not exists
mkdir -p logs
chmod 777 logs

if [ ! -f ssl/fullchain.pem ] || [ ! -f ssl/privkey.pem ]; then
    echo -e "${RED}ERROR: nginx TLS files missing: ssl/fullchain.pem and/or ssl/privkey.pem${NC}"
    echo -e "${YELLOW}Production:${NC} install real certs into ./ssl/ (e.g. certbot)."
    echo -e "${YELLOW}Dev/staging:${NC} run ${GREEN}chmod +x generate_dev_ssl.sh && ./generate_dev_ssl.sh${NC}"
    exit 1
fi

# 1. Determine current active environment
if grep -q "backend_blue" upstream.inc; then
    ACTIVE="blue"
    INACTIVE="green"
else
    ACTIVE="green"
    INACTIVE="blue"
fi

echo -e "Active environment: ${GREEN}$ACTIVE${NC}"
echo -e "Deploying to: ${YELLOW}$INACTIVE${NC}"

# 2. Postgres and Nginx must be up
echo -e "${YELLOW}Step 1: Ensuring Postgres and Nginx are up...${NC}"
docker compose -f docker-compose.prod.yml up -d postgres nginx db_backup
MAX_PG=60
COUNT_PG=0
until [ "$(docker inspect -f '{{.State.Health.Status}}' catcoin_postgres 2>/dev/null)" == "healthy" ]; do
    if [ $COUNT_PG -ge $MAX_PG ]; then
        echo -e "${RED}ERROR: Postgres did not become healthy in time.${NC}"
        exit 1
    fi
    echo -n "."
    sleep 2
    COUNT_PG=$((COUNT_PG+1))
done
echo -e "\n${GREEN}Postgres is healthy.${NC}"

# 1.5 Pre-deployment Backup
echo -e "${YELLOW}Step 1.5: Taking a last-minute pre-deployment backup...${NC}"
chmod +x backup_db.sh
./backup_db.sh || { echo -e "${RED}ERROR: Pre-deployment backup failed! Aborting.${NC}"; exit 1; }

# 3. Build the inactive backend image
echo -e "${YELLOW}Step 2: Building $INACTIVE image...${NC}"
docker compose -f docker-compose.prod.yml build --no-cache backend_$INACTIVE

# 4. Run migrations BEFORE starting the API (startup runs create_root_user and needs current schema)
echo -e "${YELLOW}Step 3: Database migrations (Alembic + run_all_migrations.py)...${NC}"
chmod +x apply_db_migrations.sh
COMPOSE_FILE=docker-compose.prod.yml MIGRATION_SERVICE=backend_$INACTIVE ./apply_db_migrations.sh

# 5. Start the inactive backend and wait for health
echo -e "${YELLOW}Step 4: Starting $INACTIVE container...${NC}"
docker compose -f docker-compose.prod.yml up -d backend_$INACTIVE

echo -e "${YELLOW}Step 5: Waiting for $INACTIVE to pass health checks...${NC}"
MAX_RETRIES=60
COUNT=0
until [ "$(docker inspect -f '{{.State.Health.Status}}' catcoin_backend_$INACTIVE)" == "healthy" ]; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo -e "${RED}ERROR: $INACTIVE failed to become healthy. Rolling back...${NC}"
        docker compose -f docker-compose.prod.yml stop backend_$INACTIVE
        exit 1
    fi
    echo -n "."
    sleep 2
    COUNT=$((COUNT+1))
done
echo -e "\n${GREEN}$INACTIVE is healthy!${NC}"

# 6. Switch traffic
echo -e "${YELLOW}Step 6: Updating Nginx to point to $INACTIVE...${NC}"
cat > upstream.inc << EOF
upstream backend {
    server backend_$INACTIVE:8000;
}
EOF

if ! reload_nginx; then
    echo -e "${RED}ERROR: Could not reload nginx. Fix nginx/ssl (see logs above) and retry.${NC}"
    exit 1
fi

# 8. Verify health of the overall site
echo -e "${YELLOW}Step 8: Verifying deployment...${NC}"
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${PUBLIC_API_BASE}/health")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Deployment successful! Switched to $INACTIVE.${NC}"

    # Optionally stop the old environment to save resources
    echo -e "${YELLOW}Step 9: Stopping old environment ($ACTIVE)...${NC}"
    docker compose -f docker-compose.prod.yml stop backend_$ACTIVE
else
    echo -e "${RED}WARNING: Health check failed with code $HTTP_CODE!${NC}"
    echo -e "${YELLOW}Rolling back to $ACTIVE...${NC}"
    cat > upstream.inc << EOF
upstream backend {
    server backend_$ACTIVE:8000;
}
EOF
    reload_nginx || true
    exit 1
fi

echo ""
echo "🌐 Backend API: ${PUBLIC_API_BASE}"
echo "📖 API Docs: ${PUBLIC_API_BASE}/docs"
echo ""
