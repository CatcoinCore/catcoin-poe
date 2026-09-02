# Mobile configuration hardening (Flutter / Android)

Scope: `cat_poe/` Flutter app and `cat_poe/android/`. Goal: clear **dev / staging / prod** behavior for API and ads, safer defaults for open-source forks, and documented Android release posture.

## 1. Configuration model (`lib/config/app_config.dart`)

| Input | Purpose |
|--------|--------|
| `API_BASE_URL` | Backend origin (no trailing slash). **Overrides all defaults** when set. |
| `APP_ENV` | `development` \| `staging` \| `production` (also `dev` / `stage` / `prod`). Sent as `X-App-Env` on API requests. |
| `USE_PRODUCTION_API_IN_DEBUG` | When `true`, **debug** builds with **empty** `API_BASE_URL` use `RELEASE_DEFAULT_API_BASE_URL` instead of the emulator localhost default. |
| `DEBUG_DEFAULT_API_BASE_URL` | Debug fallback when `API_BASE_URL` empty (default `http://10.0.2.2:8000`). |
| `RELEASE_DEFAULT_API_BASE_URL` | Release/profile fallback when `API_BASE_URL` empty (see default in `cat_poe/lib/config/app_config.dart`). |
| `ADMOB_*_UNIT_ID` | Optional compile-time AdMob units (Android/iOS, rewarded/interstitial). |
| `ALLOW_ADMOB_TEST_FALLBACK` | Must be `true` to use Google **test** ad unit IDs in **non-debug** builds when server + dart-define units are missing. Default **false**. |

**API resolution order**

1. `API_BASE_URL` if non-empty.  
2. **Debug** (`kDebugMode`) and `USE_PRODUCTION_API_IN_DEBUG` is false → `DEBUG_DEFAULT_API_BASE_URL` (not production).  
3. Otherwise → `RELEASE_DEFAULT_API_BASE_URL`.

**Ad unit resolution (non-debug)**

1. Backend `AdminConfig` (`androidAdUnitId` / `iosAdUnitId`).  
2. Matching `ADMOB_*_UNIT_ID` dart-define.  
3. If `ALLOW_ADMOB_TEST_FALLBACK` → Google sample test IDs (logged as error).  
4. Else **empty** → ad load is skipped (no silent test ads in store builds).

**Debug** builds always use Google’s official test ad units for rewarded/interstitial.

## 2. Release ambiguity controls

- **Debug → production API:** Avoided by default: unset `API_BASE_URL` in debug targets **emulator localhost**, not your release host. Use `--dart-define=API_BASE_URL=https://YOUR_API_HOST` or `USE_PRODUCTION_API_IN_DEBUG=true` only when intentionally testing against production from a debug build.  
- **Release → test ads:** No automatic fallback to test units unless `ALLOW_ADMOB_TEST_FALLBACK=true`.

## 3. Firebase & `google-services.json`

### What is in the file (typical)

- **`project_number`**, **`project_id`**, **`mobilesdk_app_id`**: public app identifiers.  
- **`current_key` (API key)**: shipped **inside the client**; treat as a **public client identifier**, not a server secret. Risk is **abuse / quota theft**, not “decrypting user data” by itself.  
- **`package_name` / `applicationId`**: must match the Play/App Store app.

### What is *not* a substitute for server secrets

- Firebase **server** keys, **service account** JSON, **Cloud Functions** secrets, FCM **server** keys — **do not** embed these in the app.

### Hardening checklist

1. **Google Cloud Console** → APIs & Services → Credentials → restrict the Android key (Android apps + package name + SHA-1 of signing cert).  
2. **Firebase Console** → Project settings → ensure correct app entries per variant.  
3. Open-source tree: **`google-services.json` is gitignored**; use **`cat_poe/android/app/google-services.json.example`** and **`cat_poe/docs/firebase_fork_setup.md`**. Rotate keys if an unrestricted key was ever public.  
4. **AdMob App ID** in `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) is **public**; limit abuse via AdMob and Play policies.

## 4. Android release hardening (`cat_poe/android/`)

| Topic | Status / note |
|--------|----------------|
| **Minify / shrink** | `release` has `isMinifyEnabled = true`, `isShrinkResources = true`, R8 + `proguard-rules.pro`. |
| **Logging** | Dart `LoggerService.info` / `warning` no-op in `kReleaseMode`; `error` still logs via `dart:developer` (consider further reduction if logs leak PII). |
| **Exported components** | `MainActivity` is `exported="true"` (required for launcher / deep links). Notification receivers are `exported="false"`. |
| **Cleartext HTTP** | **Debug** manifest sets `usesCleartextTraffic="true"` for local API. **Release** uses `network_security_config` with cleartext disabled. |
| **Backup** | `backup_rules.xml` + `data_extraction_rules.xml` exclude `FlutterSecureStorage` SharedPreferences from cloud backup / device transfer where supported. |
| **Network security config** | Present under `src/release/` only so debug/staging HTTP still works with the debug manifest. |

## 5. Related paths

- Flutter env implementation: `cat_poe/lib/config/app_config.dart`  
- API: `cat_poe/lib/services/api_service.dart`  
- Ads: `cat_poe/lib/services/ad_service.dart`  
- One-page build commands: **`cat_poe/docs/BUILD_RUNBOOK.md`**  
- Firebase fork setup: **`cat_poe/docs/firebase_fork_setup.md`**
