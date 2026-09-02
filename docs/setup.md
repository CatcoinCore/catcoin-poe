# Local development setup

This repository contains a Flutter client (`cat_poe`) and a Python/FastAPI backend (`cat_poe_backend`). For coordinated vulnerability reporting, see **`SECURITY.md`** at the repository root (aligned with **`docs/self-hosting.md`** and **`docs/security/final_release_readiness.md`**).

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- Python 3.11+ recommended
- Docker and Docker Compose (optional, for Postgres + API in containers)
- PostgreSQL 16+ (if you run the database without Docker)

## Backend

1. `cd cat_poe_backend`
2. Create a virtual environment and install dependencies:

   ```bash
   python -m venv .venv
   .venv\Scripts\activate   # Windows
   # source .venv/bin/activate   # macOS / Linux
   pip install -r requirements.txt
   ```

3. Copy environment template and edit values:

   ```bash
   copy .env.example .env   # Windows
   # cp .env.example .env   # macOS / Linux
   ```

4. Start PostgreSQL (Docker example):

   ```bash
   docker compose up -d postgres
   ```

   Or point `DATABASE_URL` / `DB_*` in `.env` at your own instance.

5. Run migrations (Alembic — use your project’s documented command, often):

   ```bash
   alembic upgrade head
   ```

   For a **fresh database**, set `ROOT_BOOTSTRAP_PASSWORD` and `ROOT_BOOTSTRAP_EMAIL` in `.env` before the first API start if you want startup to create the `root` admin (no default password is committed). See `cat_poe_backend/.env.example`.

   **Optional: client error mailing.** Set `ERROR_REPORT_EMAIL=ops@example.com` in `.env` (or `admin_config.error_report_email` via `PUT /admin/config`) and the backend will forward client-side error reports posted to `POST /v1/diagnostics/client-error` to that inbox. Leave both unset and the endpoint still accepts reports — it just logs them without mailing. Per-IP rate-limited to 10/hour and deduplicated per (user, fingerprint) for an hour to keep operator inboxes survivable during real outages.

6. Start the API:

   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

   If you run the **API container** from `docker compose up` (with the repo bind-mounted at `/app`), leave **`ENABLE_UVICORN_RELOAD`** unset or `0` unless you need in-container reload: uvicorn’s file watcher can hit **`OSError: [Errno 5] Input/output error`** on `/app` with some Docker Desktop / bind-mount setups. Set **`ENABLE_UVICORN_RELOAD=1`** in `.env` only if reload works reliably on your machine.

## Flutter app

1. `cd cat_poe`
2. `flutter pub get`
3. **Firebase (Android):** the real `android/app/google-services.json` is **not** in git. Copy `android/app/google-services.json.example` to `google-services.json` and replace with the file from your Firebase project, or inject it in CI — see **`cat_poe/docs/firebase_fork_setup.md`**.
4. Configure API base URL with **`--dart-define=API_BASE_URL=...`** when needed; see **`cat_poe/docs/BUILD_RUNBOOK.md`**. Use your own non-production endpoints and AdMob/Firebase projects in forks.

5. `flutter run` (debug defaults to emulator-local API per `lib/config/app_config.dart` unless overridden)

## Android release builds

Release signing uses `android/key.properties` and a keystore that **must stay local** — see Flutter’s [signing documentation](https://docs.flutter.dev/deployment/android#signing-the-app). Never commit keystores or passwords.

---

*Sections marked for maintainer review: supported Python version, exact migration commands, and any project-specific bootstrap scripts.*
