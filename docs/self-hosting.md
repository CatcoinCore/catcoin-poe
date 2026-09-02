# Self-hosting

You can run your **own** backend and point a custom build of the app at it. Self-hosters must supply **their own** credentials, TLS certificates, database, and third-party integrations (Firebase, ads, social APIs, etc.).

## What you need

1. **PostgreSQL** — create a database and user with a strong password.
2. **Environment file** — copy `cat_poe_backend/.env.example` to `.env` and set at minimum:
   - `ENVIRONMENT` — use `production` only with strong `SECRET_KEY` and `DOCS_PASSWORD` (see `config.py` validation).
   - `DATABASE_URL` or `DB_USER` / `DB_PASSWORD` / `DB_NAME`.
   - `SECRET_KEY` — long random string (for example 32+ bytes from `openssl rand -hex 32`).
   - For a **new** database with no `root` user yet, set `ROOT_BOOTSTRAP_PASSWORD` and `ROOT_BOOTSTRAP_EMAIL` so `create_root_user` can run once (see `cat_poe_backend/.env.example`).
3. **TLS** — for HTTPS in front of the API, place certificate files under `cat_poe_backend/ssl/` as described in `cat_poe_backend/ssl/README.md` and wire them into nginx or your reverse proxy.
4. **Mobile client** — build the Flutter app with your API base URL (`cat_poe/docs/BUILD_RUNBOOK.md` uses `https://api.example.com` as a stand-in; set `--dart-define` or edit `app_config.dart`). Use your own Firebase / AdMob / Play configuration; Android Firebase file: **`cat_poe/docs/firebase_fork_setup.md`**. Do not rely on someone else’s production endpoints unless explicitly allowed.

## Docker

- Local stack: `cat_poe_backend/docker-compose.yml` — copy `.env.example` to `.env` in that directory and set `DB_PASSWORD` before `docker compose up`.
- Production-oriented compose may live in `docker-compose.prod.yml`; adjust images, secrets, and volumes for your environment.

## Operational boundaries

- **No warranty** — self-hosted deployments are your responsibility (backups, updates, monitoring, rate limits, abuse prevention).
- **Branding** — see `BRANDING.md`; forks must not impersonate the official app or backend.

## After cloning this repo

If this tree or its **Git history** ever contained real secrets or private keys, rotate those credentials everywhere they were used, and consider history rewriting (`git filter-repo`) before publishing. See `SECURITY.md` and `docs/open_source_security_checklist.md`.
