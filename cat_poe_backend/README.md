# Catcoin PoE Backend

FastAPI backend for Catcoin Proof-of-Engagement application.

## Quick Start

**Secrets:** Do not commit `.env`, `.env.production`, or other live credentials. For local dev copy **`.env.example`** → `.env`. For production servers copy **`.env.production.example`** → `.env.production`, fill secrets, then run **`deploy.sh`** (it syncs `.env.production` → `.env` for Docker Compose). See **`DEPLOY_README.txt`** and **`DEPLOYMENT.md`**.

**Packaged release (zip):** on Windows, from this directory run **`.\create_deployment_package.ps1`** (optional **`-IncludeAssets`** to add `static/`). The archive includes **`.env.example`**, **`.env.production.example`**, prod compose, scripts, and **`ssl/README.md`** (place real certs on the server). See also repo root `docs/setup.md`. Security reporting: repo root **`SECURITY.md`**.

Defaults in `docker-compose.yml` match `.env.example`: user **`catpoe`**, password **`postgres`**, database **`catcoin_poe`**.

### Test the full backend in Docker (before production)

Use **`docker-compose.yml`** (not `docker-compose.prod.yml`): API is published on host port **`18080`** by default (maps to container `8000`). Docker Desktop on Windows often errors on `8000:8000`; set **`BACKEND_HOST_PORT=8000`** (or another port) in `.env` if you prefer. Postgres on **5432**, source bind-mounted at **`/app`**. **`uvicorn --reload` is off by default** in Compose (reload file-watching can hit `OSError: [Errno 5] Input/output error` on `/app` with some mounts). Set **`ENABLE_UVICORN_RELOAD=1`** in `.env` to opt in, or run **`uvicorn main:app --reload`** on the host with only Postgres in Docker (see below).

```bash
cd cat_poe_backend
cp -n .env.example .env   # optional: set SECRET_KEY, ROOT_BOOTSTRAP_*, etc.

chmod +x local_docker_smoke.sh
./local_docker_smoke.sh
```

If Linux reports `bash\r: No such file or directory`, the script has Windows line endings. Fix once with `sed -i 's/\r$//' local_docker_smoke.sh`, or ensure Git checks it out with LF (repo `.gitattributes` sets `*.sh text eol=lf`).

Or manually:

```bash
docker compose up -d --build
chmod +x apply_db_migrations.sh && ./apply_db_migrations.sh
docker compose port backend 8000   # shows host:port (default 0.0.0.0:18080)
curl -s "http://127.0.0.1:$(docker compose port backend 8000 | sed -n 's/.*:\([0-9]*\)$/\1/p')/health"
```

- **Swagger**: `http://127.0.0.1:18080/docs` (or whatever `BACKEND_HOST_PORT` you set)  
- **Flutter / app**: `http://127.0.0.1:18080` (desktop / iOS simulator), `http://10.0.2.2:18080` (Android emulator), or `--dart-define=API_BASE_URL=http://YOUR_LAN_IP:18080` on a physical device.

Production-like blue/green + nginx + TLS is **`docker-compose.prod.yml`** and **`mirror_deploy.sh`**; use that only when you are ready to match the live server.

### Database migrations (keep local = remote)

All deploy paths run the same two steps via **`apply_db_migrations.sh`**:

1. **`alembic upgrade head`**
2. **`python run_all_migrations.py`** (ordered scripts in `MIGRATIONS`, including **`seed_admin_config_from_env.py`** — copies integration secrets from `.env` into empty `admin_config` columns on first deploy; set **`ADMIN_CONFIG_ENV_FORCE=1`** to always overwrite from env)

Used by **`local_docker_smoke.sh`**, **`mirror_deploy.sh`**, and **`deploy.sh`**. When you change the schema, add an Alembic revision under `alembic/versions/` and/or a new script and list it in **`run_all_migrations.py`**. **`main.py` startup** only patches a few legacy columns; do not rely on it as the primary migration path.

Local **`docker-compose.yml`** loads **`env_file: .env`** on the backend service so the same variables are available as on production.

### Postgres in Docker, API on the host

```bash
docker compose up -d postgres
pip install -r requirements.txt
uvicorn main:app --reload
```

Set `DATABASE_URL` in `.env` to `postgresql+asyncpg://catpoe:postgres@localhost:5432/catcoin_poe` (or your chosen credentials).

### View API documentation (when API is running)

- **Full stack in Docker** (default `BACKEND_HOST_PORT`): `http://127.0.0.1:18080/docs` and `/redoc`
- **Uvicorn on the host**: `http://127.0.0.1:8000/docs` and `/redoc`

## Stop local stack

```bash
docker compose down
```

Remove the database volume (wipes local data):

```bash
docker compose down -v
```

## Configuration

Edit `.env` file to change database credentials or other settings.

**Bootstrap admin:** If the `root` user does not exist, startup and `create_root_user.py` create it only when `ROOT_BOOTSTRAP_PASSWORD` and `ROOT_BOOTSTRAP_EMAIL` are set (see `.env.example`). There are no default credentials in the repository.

**Dev scripts:** `test_endpoints.py`, `verify_deployment.py`, and `test_x_integration.py` require explicit environment variables for any account credentials; see comments in `.env.example`.
