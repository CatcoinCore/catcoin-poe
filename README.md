# Catcoin PoE

A Flutter mobile client and FastAPI backend for **Catcoin Proof-of-Engagement** — a daily-mining loyalty layer with social verification, referrals, and game-based rewards.

This monorepo contains two top-level packages:

| Path | What it is |
| --- | --- |
| [cat_poe/](cat_poe/) | Flutter client (Android / iOS / Windows). Mining UI, games, wallet, social verification flows. |
| [cat_poe_backend/](cat_poe_backend/) | FastAPI backend, PostgreSQL, JWT auth, admin console API. |

## Quick start

### Backend (Docker)

```bash
cd cat_poe_backend
cp .env.example .env             # set SECRET_KEY, ADMIN_CONFIG_SECRETS_KEY, ROOT_BOOTSTRAP_*
./local_docker_smoke.sh           # builds + runs migrations + boots API on :18080
```

API at `http://127.0.0.1:18080`, Swagger at `/docs`. Full instructions: [cat_poe_backend/README.md](cat_poe_backend/README.md).

### Flutter client

```bash
cd cat_poe
cp android/app/google-services.json.example android/app/google-services.json
# then replace placeholder values per docs/firebase_fork_setup.md
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:18080
```

Build runbook (dev / staging / prod): [cat_poe/docs/BUILD_RUNBOOK.md](cat_poe/docs/BUILD_RUNBOOK.md).

## Documentation map

| Topic | Where |
| --- | --- |
| Local setup (backend + client) | [docs/setup.md](docs/setup.md) |
| Self-hosting | [docs/self-hosting.md](docs/self-hosting.md) |
| Open-source security checklist | [docs/open_source_security_checklist.md](docs/open_source_security_checklist.md) |
| Final release readiness | [docs/security/final_release_readiness.md](docs/security/final_release_readiness.md) |
| Forking guide | [FORK.md](FORK.md) |
| Backend deployment | [cat_poe_backend/DEPLOYMENT.md](cat_poe_backend/DEPLOYMENT.md) |
| Backend migrations | [cat_poe_backend/MIRROR_DEPLOY_README.md](cat_poe_backend/MIRROR_DEPLOY_README.md) |
| Mobile auth contract | [cat_poe/docs/mobile_auth_contract_update.md](cat_poe/docs/mobile_auth_contract_update.md) |
| Firebase setup (forks) | [cat_poe/docs/firebase_fork_setup.md](cat_poe/docs/firebase_fork_setup.md) |
| Privacy policy | [privacy-policy.md](privacy-policy.md) |
| App store description | [play_store_description.md](play_store_description.md) |
| Branding & trademarks | [BRANDING.md](BRANDING.md) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues, PRs, and ideas welcome. By participating you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Report vulnerabilities privately — do **not** open a public issue for exploitable bugs. See [SECURITY.md](SECURITY.md) for the disclosure process.

## License

Source code is licensed under the terms of [LICENSE](LICENSE) (MIT). Project name, logos, mascots, and store listing assets are **not** automatically licensed; see [BRANDING.md](BRANDING.md). Forks and derivative apps must use their own branding and credentials per [FORK.md](FORK.md).
