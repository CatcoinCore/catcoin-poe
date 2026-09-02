# Catcoin PoE — backend deployment package

## Contents

- Application code, `docker-compose.prod.yml`, `Dockerfile`, nginx/ssl layout references
- **`.env.example`** — local / dev template
- **`.env.production.example`** — production template (no secrets). Copy and fill on the server.

## On the server

```bash
cd /opt/catcoin-backend   # or your extract path

# 1) Production secrets (never commit this file)
cp .env.production.example .env.production
chmod 600 .env.production
nano .env.production      # SECRET_KEY (24+ chars), DOCS_PASSWORD, DB_PASSWORD, SMTP, bootstrap, etc.

# 2) TLS material for nginx (see DEPLOYMENT.md)
mkdir -p ssl
# Place fullchain.pem and privkey.pem under ./ssl/

# 3) Deploy (copies .env.production → .env for Docker Compose, then builds & starts stack)
chmod +x deploy.sh apply_db_migrations.sh
./deploy.sh
```

`PUBLIC_API_BASE` defaults to `https://poe.catcoin.in` in `deploy.sh` if unset.

Full detail: **DEPLOYMENT.md**.
