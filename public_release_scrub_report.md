# Public open-source snapshot — scrub audit report

**Scope:** Full repository scan with extra attention to seeds, fixtures, migrations, templates, setup/deploy docs, scripts, and examples.  
**Date:** 2026-04-13  
**Method:** Pattern search (`rg`/IDE) for credentials, infrastructure identifiers, production URLs, integration IDs, and path leaks. **Git history was not scanned** — see [Human review](#files-requiring-human-review-before-snapshotting).

**Update (same day):** Priority 0 and the listed Priority 1 / selected Priority 2 / Priority 3 script fixes were applied in the repository; see root **`CHANGE_SUMMARY.md`** for the exact file list. Finding tables below retain **structure and severity** but **literal credentials, ids, and infra fingerprints are redacted** so this file is safe to publish; line numbers may drift.

**Legend**

| Class | Meaning |
| --- | --- |
| **1 — Remove** | Should not ship in a public tree (secrets, live infra fingerprints, or unsafe bootstrap defaults that duplicate credentials). |
| **2 — Placeholder** | OK to keep conceptually; replace literals with neutral placeholders (`YOUR_*`, `example.com`, Google sample IDs) before publishing. |
| **3 — Keep** | Intentional public branding/metadata, standard dev/CI placeholders, or non-secret API surface documentation. |

---

## Executive summary

The highest risk items are **hardcoded bootstrap admin credentials and a personal email** in `create_root_user.py`, mirrored in `test_endpoints.py`, plus a **public server IPv4** in `deploy.sh`. Next are **production AdMob application IDs** and **publisher-specific ad unit IDs** embedded in client manifests and an Alembic migration. A large amount of **production hostname and deep-link** configuration (`poe.catcoin.in`, `catcoin.in`) is baked into Flutter defaults, Android App Links, i18n strings, nginx, and backend redirects — treat as **branding vs. fork-hosting** decision. Several scripts contain **developer-local absolute paths** and one script references a **specific X username** used as a test fixture.

**No `google-services.json`**, **no `firebase_options.dart`**, and **no tracked `.env`** were found in the current tree (good). **Do** run history-aware secret scanning before publishing (`docs/security/history_rewrite_plan.md`, `docs/open_source_security_checklist.md`).

---

## Prioritized findings (path + line)

### Priority 0 — address before any public snapshot

| ID | Class | File | Lines | Finding |
| --- | --- | --- | --- | --- |
| P0-1 | **1** | `cat_poe_backend/create_root_user.py` | *(see CHANGE_SUMMARY)* | Hardcoded **bootstrap password** and **personal email** for user `root` / admin (literal values removed from this report). |
| P0-2 | **1** | `cat_poe_backend/test_endpoints.py` | *(see CHANGE_SUMMARY)* | Same **bootstrap-class password** with user `root` for local API testing (redacted here). |
| P0-3 | **1** | `cat_poe_backend/deploy.sh` | *(see CHANGE_SUMMARY)* | Comment exposed **live host mapping**: public API hostname plus a **static public IPv4** (redacted) — infrastructure fingerprint. |

### Priority 1 — production / tenant-specific identifiers

| ID | Class | File | Lines | Finding |
| --- | --- | --- | --- | --- |
| P1-1 | **2** | `cat_poe/ios/Runner/Info.plist` | *(see CHANGE_SUMMARY)* | `GADApplicationIdentifier` held a **non-sample** AdMob **application** id (`ca-app-pub-*~*` publisher-specific; redacted). |
| P1-2 | **2** | `cat_poe/android/app/src/main/AndroidManifest.xml` | *(see CHANGE_SUMMARY)* | Same **APPLICATION_ID** as P1-1 in Android manifest. |
| P1-3 | **2** | `cat_poe_backend/alembic/versions/update_ad_unit_ids.py` | *(see CHANGE_SUMMARY)* | Migration SQL set **publisher-specific** AdMob **ad unit** ids and referenced a matching app id suffix (all redacted; pattern `ca-app-pub-*`). |
| P1-4 | **2** | `cat_poe_backend/seed_missions.py` | *(see CHANGE_SUMMARY)* | Seeded real **Discord invite**, **X community** URL (numeric id), and **Telegram** channel slug (identifiers redacted). |
| P1-5 | **2** | `cat_poe_backend/fix_x_mission.py` | *(see CHANGE_SUMMARY)* | One-off SQL aligned with same **X community** numeric id as P1-4 (redacted). |
| P1-6 | **2** | `cat_poe_backend/update_x_community.py` | *(see CHANGE_SUMMARY)* | Hardcoded **X community** numeric id and derived URL (redacted). |

### Priority 2 — production URLs, emails, and fork-unfriendly defaults

| ID | Class | File | Lines | Finding |
| --- | --- | --- | --- | --- |
| P2-1 | **2** *(or **3** if you affirm brand)* | `cat_poe/lib/config/app_config.dart` | 63 | `RELEASE_DEFAULT_API_BASE_URL` default `https://poe.catcoin.in`. |
| P2-2 | **2** *(or **3**)* | `cat_poe/android/app/src/main/AndroidManifest.xml` | 44–49 | App Link host `poe.catcoin.in` for `/invite/`. |
| P2-3 | **2** *(or **3**)* | `cat_poe/lib/services/link_service.dart` | 37 | Comment/doc tied to `https://poe.catcoin.in/invite/`. |
| P2-4 | **2** *(or **3**)* | `cat_poe/lib/l10n/app_*.arb` | e.g. `app_en.arb` ~704 | `referralsShareMessage` contains `https://poe.catcoin.in/invite/{code}` (many locales + generated `app_localizations_*.dart`). |
| P2-5 | **2** *(or **3**)* | `cat_poe_backend/nginx.conf` | 12, 20 | `server_name poe.catcoin.in`. |
| P2-6 | **2** *(or **3**)* | `cat_poe_backend/mirror_deploy.sh` | *(updated)* | Was: production hostname hardcoded in `curl`/`echo`; now overridable via `PUBLIC_API_BASE` (see CHANGE_SUMMARY). |
| P2-7 | **2** *(or **3**)* | `cat_poe_backend/deploy.sh` | *(updated)* | Was: echo lines fixed to branded host; now uses `PUBLIC_API_BASE`. |
| P2-8 | **2** *(or **3**)* | `cat_poe_backend/DEPLOY_README.txt` | *(updated)* | Was: verify `curl` used fixed public API host; now placeholder host in doc. |
| P2-9 | **2** *(or **3**)* | `cat_poe_backend/main.py` | 471, 480, 505 | Redirects / defaults to `https://catcoin.in` and `https://catcoin.in/download`. |
| P2-10 | **2** *(or **3**)* | `cat_poe_backend/models.py` | 367–377 | Defaults for Play/App Store / Windows update URLs include `org.catcoin.cat`, `id123456789`, `https://catcoin.in/download`. |
| P2-11 | **2** *(or **3**)* | `cat_poe/lib/models/admin_config.dart` | 202–212 | Client-side JSON defaults for store + `https://catcoin.in/download`. |
| P2-12 | **2** *(or **3**)* | Multiple Alembic versions / `update_x_credentials_schema.py` | various | Server defaults for update URLs and Windows download host `catcoin.in` (same pattern as models). |
| P2-13 | **2** | `cat_poe_backend/services/email_service.py` | 36, 113 | Fallback sender `noreply@catcoin.in` when `SMTP_EMAIL` unset. |
| P2-14 | **2** | `cat_poe_backend/verify_deployment.py` | *(see CHANGE_SUMMARY)* | Default **test account email** at project domain and **weak default password** for wallet API checks (redacted; removed in code). |
| P2-15 | **2** | `cat_poe_backend/static/.well-known/apple-app-site-association` | 6 | `appID`: `TEAMID.org.catcoin.catPoe` — `TEAMID` is a placeholder; **bundle id** is product-specific. |
| P2-16 | **2** | `cat_poe/update_l10n.dart` | *(fixed)* | Hardcoded **absolute Windows path** to `lib/l10n` (machine layout; redacted; now script-relative). |
| P2-17 | **2** | `cat_poe/update_runner_names.dart` | *(fixed)* | Same as P2-16. |
| P2-18 | **2** | `cat_poe_backend/create_deployment_package.ps1` | *(fixed)* | Hardcoded **absolute path** to backend tree (redacted; now `$PSScriptRoot`). |

### Priority 3 — test / integration scripts and hygiene

| ID | Class | File | Lines | Finding |
| --- | --- | --- | --- | --- |
| P3-1 | **2** | `cat_poe_backend/test_x_integration.py` | *(see CHANGE_SUMMARY)* | Hardcoded **personal / org X username** as follow-graph test fixture (redacted; use `X_TEST_OWNER_USERNAME`). |
| P3-2 | **2** | `cat_poe_backend/temp_deploy_staging/` | (tree) | Partial duplicate of backend files (`services/`, `templates/`). Not secrets in the sampled files, but **stale mirror** risk and extra review surface for a public repo. |
| P3-3 | **3** | `.github/workflows/ci.yml` | 33–35 | `SECRET_KEY: ci-test-secret-key-not-for-production-use` and local Postgres URL — clearly non-production. |
| P3-4 | **3** | `cat_poe_backend/alembic.ini` | 55 | `postgresql://postgres:password@localhost/catcoin_poe` — generic local dev convention. |
| P3-5 | **3** | `cat_poe_backend/tests/README.md` | 23, 179 | Example test DB URL with `password` on localhost. |
| P3-6 | **3** | `verify_discord_config.py` / `verify_telegram_config.py` | various | Read tokens from `.env` only; **do not** commit `.env`. |
| P3-7 | **3** | `cat_poe/lib/config/app_config.dart` | 67–74 | Google **official sample** AdMob unit IDs (`ca-app-pub-3940256099942544/...`) — safe for debug/docs. |
| P3-8 | **3** | `cat_poe/android/app/google-services.json.example` | (file) | Placeholder Firebase JSON — good pattern. |
| P3-9 | **3** | `discord_bot_setup.md`, `telegram_setup.md`, `twitter_setup.md` | various | Instructional docs with placeholders (`YOUR_*`). |
| P3-10 | **3** | `docs/security/history_rewrite_plan.md` | — | **Meta:** inventory of paths that **must not** be committed; reminder to scan **git history** if they ever were. |

### Intentional public branding / product metadata (class **3**)

- **Android:** `applicationId` / namespace `org.catcoin.cat` / `org.catcoin.cat_poe` — public store identifiers (`cat_poe/android/app/build.gradle.kts`, `Info.plist`, etc.).
- **Product name strings** (“Catcoin”, “Cat Poe”) across app and docs.
- **Third-party API endpoints** (e.g. CoinGecko, X/Twitter API URL shapes, Discord/Telegram API) — not secrets; tokens belong in env/DB.

---

## Minimal patch suggestions (placeholders)

Use these as **templates**; adjust naming to your fork policy.

### A. Bootstrap admin (P0-1, P0-2)

**`create_root_user.py`:** require env vars and fail closed if unset, e.g. `ROOT_BOOTSTRAP_PASSWORD`, `ROOT_BOOTSTRAP_EMAIL` (or skip auto-create in OSS and document manual admin creation).

**`test_endpoints.py`:** `login_data` from `os.environ["TEST_ADMIN_USER"]` / `os.environ["TEST_ADMIN_PASSWORD"]` with no defaults, or delete this script from the public branch if it is internal-only.

### B. Deploy script IP (P0-3)

```bash
# Before: comment tied public API hostname to a static public IPv4 (redacted from this doc).
# After: describe hosting in runbooks only; do not commit static IPs in repo comments.
```

### C. AdMob app ID in clients (P1-1, P1-2)

Replace with [Google’s sample App ID](https://developers.google.com/admob/android/test-app-id) for open-source defaults, and document real IDs via private CI or local overrides:

- iOS: `ca-app-pub-3940256099942544~1458002511` (example from Google’s test docs — confirm current doc value when you patch).
- Android: matching sample application id from the same documentation.

### D. Alembic ad unit migration (P1-3)

Prefer **nullable** or **obviously fake** IDs in a public fork, e.g. `ca-app-pub-3940256099942544/5224354917`, **or** split: keep migration as no-op in OSS and document “set ad units via admin UI.” Editing already-applied migrations is painful; for **new** public history, replace before first publish.

### E. Seed / fix social missions (P1-4 — P1-6)

Replace with:

- `https://discord.gg/YOUR_INVITE`
- `https://t.me/YOUR_CHANNEL`
- `https://x.com/i/communities/YOUR_COMMUNITY_ID`

…or load from env / YAML seed file not committed with real values.

### F. Production API + invite URLs (P2-1 — P2-4)

- `app_config.dart`: default `RELEASE_DEFAULT_API_BASE_URL` → `https://api.example.com` or empty + documented `--dart-define`.
- `.arb` `referralsShareMessage`: `https://YOUR_API_HOST/invite/{code}` then run `flutter gen-l10n`.
- `AndroidManifest.xml` App Links: `android:host` → `YOUR_API_HOST` or remove `autoVerify` intent-filter from OSS template until fork configures Digital Asset Links.

### G. Backend marketing redirects (P2-9)

`main.py` redirects to `https://catcoin.in` → `https://YOUR_MARKETING_SITE` or relative behavior behind env `PUBLIC_WEBSITE_URL`.

### H. Email default (P2-13)

`noreply@catcoin.in` → `noreply@example.com` or require `SMTP_EMAIL` with no default.

### I. Verify deployment defaults (P2-14)

Remove defaults: `os.getenv("TEST_USER")` / `os.getenv("TEST_PASS")` must be set or exit with usage message.

### J. Developer paths (P2-16 — P2-18)

- Dart: `final l10nDir = Directory(path.join(Directory.current.path, 'lib', 'l10n'));`
- PowerShell: `$ProjectRoot = Split-Path -Parent $PSScriptRoot` (or parameterize).

### K. X integration test handle (P3-1)

`owner_username = "YOUR_TEST_ACCOUNT"` and update comments; use accounts you control or pure mock.

---

## Files requiring human review before snapshotting

Reviewers should decide **class 2 vs 3** (fork template vs intentional public brand) and whether to **delete vs rewrite**.

| Area | Paths |
| --- | --- |
| **Credentials & bootstrap** | `cat_poe_backend/create_root_user.py`, `cat_poe_backend/test_endpoints.py`, `cat_poe_backend/deploy.sh`, `cat_poe_backend/verify_deployment.py` |
| **Ads & store IDs** | `cat_poe/ios/Runner/Info.plist`, `cat_poe/android/app/src/main/AndroidManifest.xml`, `cat_poe_backend/alembic/versions/update_ad_unit_ids.py`, `cat_poe/lib/models/admin_config.dart`, `cat_poe_backend/models.py`, related Alembic version files with `update_url_*` defaults |
| **Social / community seeds** | `cat_poe_backend/seed_missions.py`, `cat_poe_backend/fix_x_mission.py`, `cat_poe_backend/update_x_community.py` |
| **API & deep linking** | `cat_poe/lib/config/app_config.dart`, `cat_poe/lib/services/link_service.dart`, `cat_poe/android/app/src/main/AndroidManifest.xml`, `cat_poe/lib/l10n/*.arb` (+ regenerate localizations), `cat_poe_backend/static/.well-known/apple-app-site-association` |
| **Infra & deploy narrative** | `cat_poe_backend/nginx.conf`, `cat_poe_backend/mirror_deploy.sh`, `cat_poe_backend/DEPLOY_README.txt`, `cat_poe_backend/main.py` (redirects), `PHASE1_DEPLOY_README.md`, `cat_poe_backend/DEPLOYMENT.md`, `cat_poe_backend/MIRROR_DEPLOY_README.md` |
| **Email & privacy copy** | `cat_poe_backend/services/email_service.py`, `cat_poe_backend/templates/*.html`, `privacy-policy.md`, `cat_poe_backend/templates/privacy_policy.html` |
| **Developer machine leakage** | `cat_poe/update_l10n.dart`, `cat_poe/update_runner_names.dart`, `cat_poe_backend/create_deployment_package.ps1` |
| **Integration test fixtures** | `cat_poe_backend/test_x_integration.py` |
| **Stale / duplicate trees** | `cat_poe_backend/temp_deploy_staging/**` |
| **Git history** | Entire repo: run secret/history tools per `docs/security/history_rewrite_plan.md` |

---

## Suggested next steps (operations)

1. Fix **P0** in `main` (or a release branch) before making the repo public.  
2. Rotate **any** credential that ever appeared in git history (per internal security docs).  
3. Run **GitHub secret scanning** + a **history-aware** scanner on the full clone.  
4. For class **2** hostname/branding choices, publish a short **FORK.md** explaining required `--dart-define` and server-side env vars so clones do not phone home to production.

---

*End of report.*
