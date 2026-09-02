# Change summary — public scrub follow-up (2026-04-13)

Small, targeted edits from **`public_release_scrub_report.md`**: remove severity **1** exposure, replace severity **2** tenant-specific values with placeholders or official test IDs, and align docs/scripts. **Branding** hosts (`poe.catcoin.in`, `catcoin.in`) and package/bundle ids (`org.catcoin.cat`, …) were **left unchanged** per maintainer direction.

---

## Files changed and why

| File | Why |
| --- | --- |
| `cat_poe_backend/create_root_user.py` | **P0:** Removed hardcoded password and personal email. Creation of `root` now requires `ROOT_BOOTSTRAP_PASSWORD` and `ROOT_BOOTSTRAP_EMAIL`; otherwise skips with a message (startup no longer invents credentials). |
| `cat_poe_backend/test_endpoints.py` | **P0:** Removed hardcoded admin password. Requires `TEST_ADMIN_USER` and `TEST_ADMIN_PASSWORD`; optional `TEST_API_BASE_URL`. |
| `cat_poe_backend/deploy.sh` | **P0:** Removed static public IPv4 from the header comment (infra fingerprint). |
| `cat_poe_backend/DEPLOY_README.txt` | **P0:** Replaced example `scp` target IP with `YOUR_SERVER_IP`. |
| `cat_poe/ios/Runner/Info.plist` | **P1:** Replaced publisher AdMob **application** id with Google’s **iOS sample** app id (`ca-app-pub-3940256099942544~1458002511`). |
| `cat_poe/android/app/src/main/AndroidManifest.xml` | **P1:** Same for Android sample app id (`ca-app-pub-3940256099942544~3347511713`). |
| `cat_poe_backend/alembic/versions/update_ad_unit_ids.py` | **P1:** Replaced publisher-specific unit ids with Google **test** rewarded unit ids (Android/iOS samples). **Note:** If this revision already ran against a real DB, the database is unchanged until you update rows (admin UI or SQL). |
| `cat_poe_backend/seed_missions.py` | **P1:** Replaced real Discord / X / Telegram URLs with obvious placeholders (`YOUR_*`). Left `@catcoin` copy as product wording. |
| `cat_poe_backend/fix_x_mission.py` | **P1:** Placeholder X community link and `x_community_username` for one-off fix script. |
| `cat_poe_backend/update_x_community.py` | **P1:** Removed hardcoded community id; requires numeric `X_COMMUNITY_ID` in the environment. |
| `cat_poe_backend/services/email_service.py` | **P2:** Default `SMTP_EMAIL` fallback `noreply@catcoin.in` → `noreply@example.com` (real mail still uses `SMTP_EMAIL` when set). |
| `cat_poe_backend/verify_deployment.py` | **P2:** Removed default test username/password; requires `TEST_USER` and `TEST_PASS`. |
| `cat_poe/update_l10n.dart` | **P2:** Removed machine-specific absolute path; resolves `lib/l10n` from the script location. |
| `cat_poe/update_runner_names.dart` | **P2:** Same as above. |
| `cat_poe/format_bip39.py` | **P2:** Replaced stale absolute path with path relative to the script (same hygiene as l10n helpers). |
| `cat_poe_backend/create_deployment_package.ps1` | **P2:** `$ProjectRoot` uses `$PSScriptRoot` instead of a developer path. |
| `cat_poe_backend/test_x_integration.py` | **P3:** Replaced personal X handle with `X_TEST_OWNER_USERNAME` or placeholder `YOUR_X_USERNAME`. |
| `cat_poe_backend/.env.example` | Documents bootstrap and script env variables. |
| `cat_poe_backend/docker-compose.prod.yml` | Passes `ROOT_BOOTSTRAP_PASSWORD` / `ROOT_BOOTSTRAP_EMAIL` into backend containers when set on the host. |
| `cat_poe_backend/README.md` | Documents bootstrap and script credentials. |
| `cat_poe_backend/DEPLOYMENT.md` | `.env.production` example includes bootstrap variables. |
| `docs/setup.md` | Notes `ROOT_BOOTSTRAP_*` for fresh databases. |
| `docs/self-hosting.md` | Lists `ROOT_BOOTSTRAP_*` for new self-hosted DBs. |
| `cat_poe/docs/BUILD_RUNBOOK.md` | Notes sample AdMob application IDs in manifests for OSS. |
| `public_release_scrub_report.md` | Short pointer to **CHANGE_SUMMARY**; finding tables redact literal secrets for public snapshot (see **PUBLIC_SNAPSHOT_DOC_AUDIT.md**). |
| `cat_poe_backend/mirror_deploy.sh` | **Follow-up:** `PUBLIC_API_BASE` from env (after sourcing `.env.production`), default `https://poe.catcoin.in` — external `curl` health check and summary URLs no longer hardcode-only; forks override without editing the script. |
| `cat_poe_backend/deploy.sh` | Same `PUBLIC_API_BASE` for post-deploy echo URLs. |
| `cat_poe_backend/.env.example` | Documents `PUBLIC_API_BASE` for deploy/mirror scripts. |
| `cat_poe_backend/MIRROR_DEPLOY_README.md` | Corrected step order to match the script; documents `PUBLIC_API_BASE`. |
| `cat_poe_backend/DEPLOY_README.txt` | Verify step uses `YOUR_API_DOMAIN` instead of a fixed hostname. |
| `cat_poe_backend/DEPLOYMENT.md` | Notes optional `PUBLIC_API_BASE` in `.env.production`. |

---

## Still requiring human branding / product decisions

These were **not** changed in this pass (class **2 or 3** “fork vs. ship” items from the scrub report):

- **API and marketing hosts:** `RELEASE_DEFAULT_API_BASE_URL` (`https://poe.catcoin.in`), Android App Links host, referral strings in `lib/l10n/*.arb`, nginx `server_name`, backend redirects to `catcoin.in`, `DEPLOY_README.txt` / deploy echoes, etc.
- **Store / bundle identifiers:** `org.catcoin.cat`, default Play/App Store URLs in models, Alembic defaults, and `admin_config.dart` fallbacks (except where migration above touches DB defaults for **ad units** only).
- **`static/.well-known/apple-app-site-association`:** `TEAMID` remains a placeholder; real **Apple Team ID** and Universal Links policy are a release-time choice.
- **`cat_poe_backend/temp_deploy_staging/`:** Still present; consider deleting or automating so it cannot drift (hygiene, not a secret fix).
- **Git history:** Old literals may still exist in history; run history-aware secret scanning and rotate anything that ever leaked.
- **Production databases** that already applied the **old** `update_ad_unit_ids` migration: DB rows may still hold former publisher ids until updated in admin or via SQL.

---

## Behavioral notes (intentional)

- **First boot without `ROOT_BOOTSTRAP_*`:** No `root` user is created automatically; existing installs are unaffected (still promotes `root` to admin if present).
- **`test_endpoints.py` / `verify_deployment.py`:** Exit with usage-style errors unless env vars are set.
- **`update_x_community.py`:** Exits unless `X_COMMUNITY_ID` is set and numeric.

---

## Documentation-only public snapshot pass (2026-04-13)

| File | Why |
| --- | --- |
| `public_release_scrub_report.md` | Redacted **all** literal former secrets/ids/paths from finding tables and examples; kept severity + file pointers. |
| `docs/security/history_rewrite_plan.md` | Replaced “confirmed tracked” wording with **verify via `git ls-files`** before publish. |
| `docs/security/final_release_readiness.md` | Same for `.env` / `.env.production` tracking claim. |
| `PUBLIC_SNAPSHOT_DOC_AUDIT.md` | **New:** safe vs exclude lists for snapshot exports + maintainer `rg` checklist. |
| `verify_twitter_config.py` | Removed hardcoded default **X** lookup username (`catcoincore`); requires `X_COMMUNITY_USERNAME` in `.env`. |
| `cat_poe/.gemini/tmp/*.dart` (7 files) | Replaced machine-specific absolute paths with `Platform.script`-relative `cat_poe` root (same pattern as `update_l10n.dart`). |
