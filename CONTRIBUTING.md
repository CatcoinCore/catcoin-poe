# Contributing

Thanks for your interest in Catcoin PoE. This document describes how to file issues, propose changes, and pass CI.

## Code of conduct

By participating you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report any concerns privately via [SECURITY.md](SECURITY.md) (or to the maintainers directly).

## Filing issues

- **Bug reports** — include OS / Flutter / Python versions, exact steps to reproduce, and the actual vs. expected behaviour. Backend traces are very welcome; please redact tokens and personal data.
- **Feature requests** — describe the user-visible problem first; we'll discuss design trade-offs in the issue before code is written.
- **Security issues** — do **not** open a public issue. See [SECURITY.md](SECURITY.md).

## Development setup

Backend (FastAPI + Postgres):

```bash
cd cat_poe_backend
cp .env.example .env             # set SECRET_KEY, ADMIN_CONFIG_SECRETS_KEY
docker compose up -d postgres
pip install -r requirements.txt -r requirements-test.txt
uvicorn main:app --reload
```

Client (Flutter):

```bash
cd cat_poe
cp android/app/google-services.json.example android/app/google-services.json
# Replace placeholders per cat_poe/docs/firebase_fork_setup.md
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Full instructions: [docs/setup.md](docs/setup.md).

## Branches and pull requests

- Branch off `main` with a short descriptive name (e.g. `fix/leaderboard-pagination`, `feat/admin-bulk-bonus-cap`).
- Keep PRs focused on a single concern. If you bundle a refactor with a fix, separate them.
- Update or add tests for behaviour you change. CI runs:
  - **Backend:** `pytest` against PostgreSQL 16 ([.github/workflows/ci.yml](.github/workflows/ci.yml)).
  - **Client:** `flutter test` for unit + widget tests.
  - **Secrets:** gitleaks ([.github/workflows/secret-scan.yml](.github/workflows/secret-scan.yml)) — no commits with credentials.
  - **Dependencies:** dependency review on PRs.
- Don't commit `.env`, `.env.production`, real `google-services.json`, keystores, signed APKs, or any secret. The repo `.gitignore` covers most of this; please double-check `git diff --stat` before pushing.
- Sign-off in commit messages is not required, but a clear message body explaining *why* helps reviewers.

## Coding style

- **Python** — follow the existing FastAPI / SQLAlchemy patterns in `cat_poe_backend/routers/` and `services/`. Prefer Pydantic v2 idioms (`field_validator`, `model_validator`). Don't add new modules without a clear need.
- **Dart / Flutter** — match the surrounding file. Pass `flutter analyze` cleanly on changed files; treat `info` deprecations as worth fixing where they touch your change.
- **Tests** — fast unit tests preferred. Backend integration tests live under `cat_poe_backend/tests/` and use a real ephemeral Postgres database (`catcoin_poe_test`). Flutter tests under `cat_poe/test/` are widget / unit only.
- **Docs** — if you change a build step, an env var, or a public surface, update the relevant doc in the same PR. Maintainers are strict about doc drift.

## Branding and forks

Catcoin name, logo, and store assets are **not** under the code license. If you fork to ship your own product, see [FORK.md](FORK.md) for the host overrides and bundle-id changes you need to make.

## License

By contributing you agree that your contributions will be licensed under the same MIT [LICENSE](LICENSE) that covers the rest of the source code.
