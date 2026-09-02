# Forking guide

This repository ships with the official Catcoin branding, hosts, and identifiers baked into a few specific places. **Forks must override them** to avoid phoning home to the official infrastructure or implying official endorsement.

See also [BRANDING.md](BRANDING.md) for the trademark / asset rules, and [docs/security/final_release_readiness.md](docs/security/final_release_readiness.md) for the maintainer release checklist.

## What you must change

### 1. Backend host references (your server)

The client targets the official API by default. Override at build time so your fork hits your own backend:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.your-fork.example
```

Files that hardcode `https://poe.catcoin.in` or `https://catcoin.in` and that you may need to mirror for full Cut-over:

| File | Purpose |
| --- | --- |
| [cat_poe/lib/config/app_config.dart](cat_poe/lib/config/app_config.dart) | `RELEASE_DEFAULT_API_BASE_URL` — the fallback when no `--dart-define` is supplied. |
| [cat_poe/android/app/src/main/AndroidManifest.xml](cat_poe/android/app/src/main/AndroidManifest.xml) | Android App Links host for `/invite/...`. |
| [cat_poe/lib/l10n/app_*.arb](cat_poe/lib/l10n/) | Referral-share strings (`referralsShareMessage`) per locale. Re-run `flutter gen-l10n` after editing. |
| [cat_poe_backend/nginx.conf](cat_poe_backend/nginx.conf) | `server_name` for the production reverse proxy. |
| [cat_poe_backend/main.py](cat_poe_backend/main.py) | Marketing redirects (lines around 471 / 480 / 505). |

For deploy/mirror scripts the host is now read from the `PUBLIC_API_BASE` env var (see [cat_poe_backend/.env.production.example](cat_poe_backend/.env.production.example)) — set that and you don't need to edit `deploy.sh` / `mirror_deploy.sh`.

### 2. Bundle / package identifiers (your store listing)

Catcoin uses `org.catcoin.cat` (Android) and `org.catcoin.catPoe` (iOS associated-domains). You must change these before submitting to a store — Google Play and the App Store reject duplicates of an existing publisher's bundle.

| File | What to change |
| --- | --- |
| [cat_poe/android/app/build.gradle.kts](cat_poe/android/app/build.gradle.kts) | `applicationId` and `namespace`. |
| [cat_poe/android/app/src/main/AndroidManifest.xml](cat_poe/android/app/src/main/AndroidManifest.xml) | Package name, App Links host. |
| [cat_poe/ios/Runner/Info.plist](cat_poe/ios/Runner/Info.plist) | `CFBundleIdentifier`, `GADApplicationIdentifier`. |
| [cat_poe/ios/Runner.xcodeproj/project.pbxproj](cat_poe/ios/Runner.xcodeproj/project.pbxproj) | `PRODUCT_BUNDLE_IDENTIFIER`. |
| [cat_poe_backend/static/.well-known/apple-app-site-association](cat_poe_backend/static/.well-known/apple-app-site-association) | Replace `TEAMID.org.catcoin.catPoe` with **your** Team ID and bundle id. |
| [cat_poe_backend/static/.well-known/assetlinks.json](cat_poe_backend/static/.well-known/assetlinks.json) | Android Digital Asset Links — your app's SHA-256 cert fingerprint and package name. |

### 3. Firebase project (your own)

`google-services.json` is **gitignored**. Don't reuse the official one.

1. Create a Firebase project for your fork's package id.
2. Copy `cat_poe/android/app/google-services.json.example` → `google-services.json` and replace placeholders with the values from your Firebase console.
3. Follow [cat_poe/docs/firebase_fork_setup.md](cat_poe/docs/firebase_fork_setup.md) for SHA-1/SHA-256 fingerprints, API restrictions, and the AdMob app-id swap.

### 4. AdMob IDs (yours, not Google samples)

The repo currently ships **Google's official sample AdMob IDs** so the build works without an account. Before you publish, replace them with your own publisher IDs in:

- [cat_poe/ios/Runner/Info.plist](cat_poe/ios/Runner/Info.plist) — `GADApplicationIdentifier`.
- [cat_poe/android/app/src/main/AndroidManifest.xml](cat_poe/android/app/src/main/AndroidManifest.xml) — `APPLICATION_ID` meta-data.
- DB rows for ad units — set via `PUT /admin/config` (`android_ad_unit_id`, `ios_ad_unit_id`) once your backend is live; do **not** edit the historical Alembic migration.

### 5. Backend secrets (yours, never commit)

Set in `.env` / `.env.production`, never in source:

- `SECRET_KEY` — JWT signing key (32+ random bytes).
- `ADMIN_CONFIG_SECRETS_KEY` — Fernet key for at-rest encryption of admin tokens. **Required** in non-development environments. Generate with:
  ```bash
  python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
  ```
- `ROOT_BOOTSTRAP_PASSWORD` / `ROOT_BOOTSTRAP_EMAIL` — credentials for the auto-created admin on first DB boot. Without these set, no admin is created and you must create one manually.
- `DOCS_PASSWORD` — required in non-dev so `/docs` and `/redoc` aren't open.
- Bot tokens (`DISCORD_BOT_TOKEN`, `TELEGRAM_BOT_TOKEN`, `X_*`) — only if you wire those integrations.

### 6. Branding & assets

The Catcoin name, mascot, store icons, splash screens, and launch images are **not** under the code license. See [BRANDING.md](BRANDING.md). Replace:

- `cat_poe/android/app/src/main/res/mipmap-*/ic_launcher.png`
- `cat_poe/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `cat_poe/assets/` (mascot art, splash, etc.)
- App display name in `AndroidManifest.xml` (`android:label`) and `Info.plist` (`CFBundleDisplayName`).
- Store listing copy in [play_store_description.md](play_store_description.md).

### 7. Privacy & support contact

[privacy-policy.md](privacy-policy.md) and any in-app "About" / "Help" surfaces must point to **your** support and privacy contact before you publish to a store.

## Going live checklist

Before pushing your first build to a store:

- [ ] `--dart-define=API_BASE_URL=...` points at your backend, not the default.
- [ ] Bundle / package identifier is yours (and not `org.catcoin.cat*`).
- [ ] `google-services.json` is from your Firebase project.
- [ ] AdMob application id and ad-unit ids are yours (not Google samples) where applicable.
- [ ] `assetlinks.json` and `apple-app-site-association` carry your team / SHA-256 / bundle.
- [ ] Backend `.env.production` has `SECRET_KEY`, `ADMIN_CONFIG_SECRETS_KEY`, `DOCS_PASSWORD`, `ROOT_BOOTSTRAP_*`.
- [ ] App icons, splash screens, mascot art, and display name are yours.
- [ ] Privacy policy resolves to a working contact channel you control.
- [ ] You ran `gitleaks` on the full history of your fork before going public.

If you hit something the official repo wires up that this guide misses, please open a PR — the goal is for forks to be a drop-in, not an excavation.
