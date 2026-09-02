# Catcoin PoE — local dev, staging, prod (one page)

All commands assume a shell in **`cat_poe/`** unless noted. Repeat **`--dart-define=...`** for each key (same `flutter` invocation).

**Production API host in examples:** use `https://api.example.com` as a stand-in. Your real default when `API_BASE_URL` is unset is **`RELEASE_DEFAULT_API_BASE_URL`** in `lib/config/app_config.dart` — set `--dart-define` or change that constant for your deployment.

## Prerequisites

| Item | Notes |
|------|--------|
| Flutter SDK + Android SDK | As for any Flutter Android project. |
| **`android/app/google-services.json`** | **Not in git.** Copy from template: `cp android/app/google-services.json.example android/app/google-services.json`, then replace with the file downloaded from Firebase (see [firebase_fork_setup.md](firebase_fork_setup.md)). |
| **`android/key.properties` + keystore** | Required for Play **release** builds only (see `android/.gitignore`). |

**Profile builds:** `flutter run --profile` is not `kDebugMode`. With no `API_BASE_URL`, the app uses the **release default** API host. Set `API_BASE_URL` when profiling against a local backend.

---

## Development (debug)

**API:** local Docker publishes the backend on **`18080`** by default (`BACKEND_HOST_PORT` in `cat_poe_backend/.env`). Cleartext HTTP is allowed in debug only.

| Where you run the app | Default base URL (no `--dart-define`) |
|-----------------------|----------------------------------------|
| Android **emulator** | `http://10.0.2.2:18080` (special alias to your PC) |
| iOS Simulator / desktop / web | `http://127.0.0.1:18080` |

**Physical Android phone (USB or Wi‑Fi):** `10.0.2.2` does **not** work — it only exists on the emulator. You must point the app at your PC explicitly.

**Option A — same Wi‑Fi as the PC (replace with your PC’s LAN IP):**

```bash
cd cat_poe
flutter pub get
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:18080
```

Ensure the backend is reachable from the LAN (Docker maps `0.0.0.0:18080` by default). If the connection still fails, allow **Python / Docker** through Windows Firewall for port **18080**.

**Option B — USB debugging with port reverse** (traffic to the phone’s loopback is forwarded to the PC):

```bash
adb reverse tcp:18080 tcp:18080
cd cat_poe
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:18080
```

Re-run `adb reverse` after reconnecting the cable if needed.

**Firebase:** use `google-services.json` from Firebase with your **debug** SHA-1 registered (see [firebase_fork_setup.md](firebase_fork_setup.md)).

```bash
cd cat_poe
flutter pub get
flutter run
```

**Emulator + custom API port on host:**

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:18080
```

**Debug build calling production API:**

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

**Or** keep empty `API_BASE_URL` but use release default host from a debug build:

```bash
flutter run --dart-define=USE_PRODUCTION_API_IN_DEBUG=true
```

(`API_BASE_URL` wins whenever set.)

---

## Staging

Use your staging backend and optional **staging** AdMob unit IDs (or rely on server admin config).

**Debug APK (installable, staging API):**

```bash
cd cat_poe
flutter build apk --debug \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging.example.com
```

**Release-mode APK (no debugger, still needs real signing for some devices):**

```bash
flutter build apk --release \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging.example.com \
  --dart-define=ADMOB_ANDROID_REWARDED_UNIT_ID=ca-app-pub-XXXXXXXX/rewarded_id \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_UNIT_ID=ca-app-pub-XXXXXXXX/interstitial_id
```

**App bundle (Play internal testing track):**

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging.example.com
```

---

## Production (Play Store / release)

**App bundle (typical Play upload):**

```bash
cd cat_poe
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

**Release APK (side-load / non-Play):**

```bash
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

**Omitting `API_BASE_URL`** uses compile-time **`RELEASE_DEFAULT_API_BASE_URL`** from `lib/config/app_config.dart` (replace `https://api.example.com` in commands with that value, or your own host).

**AdMob:** The checked-in `AndroidManifest.xml` and iOS `Info.plist` use **Google’s sample AdMob application IDs** for open-source safety; substitute your real AdMob app id before store release. If your backend admin config supplies real unit IDs, extra `--dart-define` AdMob keys are optional. Do **not** set `ALLOW_ADMOB_TEST_FALLBACK` for store builds unless you intentionally want Google test units.

---

## QA: release binary with test ads only (explicit)

```bash
cd cat_poe
flutter build apk --release \
  --dart-define=ALLOW_ADMOB_TEST_FALLBACK=true \
  --dart-define=API_BASE_URL=https://api.example.com
```

---

## OSS / fork quick reference

| Goal | `google-services.json` | Typical defines |
|------|-------------------------|-----------------|
| Local dev + emulator API | Your Firebase project + debug SHA-1 | none |
| Fork + staging | Your Firebase project | `API_BASE_URL`, `APP_ENV=staging` |
| Store production | Your Firebase + release SHA + AdMob app id in manifest | `API_BASE_URL`, `APP_ENV=production`, signing via `key.properties` |

Full Firebase steps: **[firebase_fork_setup.md](firebase_fork_setup.md)**.
