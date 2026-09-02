# Flutter / Android open-source release audit

**Scope:** `cat_poe/lib/**`, `cat_poe/android/**` (Flutter app + Android only).  
Line numbers refer to the tree at audit time.

> **OSS update:** Real **`android/app/google-services.json`** is **gitignored**; the repo carries **`google-services.json.example`**. API base URL and env behavior are documented in **`cat_poe/lib/config/app_config.dart`**, **`cat_poe/docs/BUILD_RUNBOOK.md`**, and **`docs/security/mobile_config_hardening.md`**. For a current go/no-go list, use **`docs/security/final_release_readiness.md`** — many line references below may be stale.  
> **Placeholders:** deployment guides use **`YOUR_API_DOMAIN`** / **`api.example.com`**. Hosts, schemes, and package IDs in the tables below use **`YOUR_*`** stand-ins so this doc is safe to publish; match filenames to your tree and substitute your real values when auditing a fork.

---

## 1. Executive summary

| Area | Status |
|------|--------|
| **API base URL** | Single production host hardcoded; optional override added via `--dart-define=API_BASE_URL` (see patches). |
| **Secrets in repo** | No private signing secrets in Gradle; `key.properties` / keystore are local. **Firebase:** real `google-services.json` is **local/CI only** (gitignored); template is **`google-services.json.example`**. Keys in a developer’s downloaded file are client identifiers — **restrict** in Google Cloud. **AdMob application ID** in manifest is **public-by-design**. |
| **Release shrink/obfuscate** | `isMinifyEnabled` / `isShrinkResources` **true** (`android/app/build.gradle.kts` 68–69). No custom `proguard-rules.pro` was present; **added** minimal rules + `proguardFiles` reference. |
| **Dev/staging/prod** | **No distinct staging flavor**; debug and release both defaulted to `https://YOUR_API_HOST` before patch. **Backend mission verification** sees `X-Client-Env: debug` vs `release` (`api_service.dart` 77, 220). |
| **Network security** | No `android:networkSecurityConfig` or `usesCleartextTraffic`; HTTPS-only for API in practice. |
| **Backup / exported** | `MainActivity` `android:exported="true"` (required for launcher / App Links). `allowBackup` not set (platform default **true** — human should verify in manifest if backups must be off). |

---

## 2. Hardcoded URLs and hosts (exact references)

| Location | Lines | Value / note |
|----------|-------|----------------|
| `lib/services/api_service.dart` | 25–37 | `https://YOUR_API_HOST` (all modes before audit); emulator localhost commented 30, 33. |
| `lib/services/blockchain_service.dart` | 6–7 | `https://chainz.cryptoid.info/cat/api.dws` (third-party explorer; not a secret). |
| `lib/models/admin_config.dart` | 202–212 | Default `updateUrlAndroid`, `updateUrlIOS`, `updateUrlWindows` include Play/App Store / **YOUR_BRAND_DOMAIN** URLs. |
| `lib/l10n/app_en.arb` | 704 | Share text: `https://YOUR_API_HOST/invite/{code}`. |
| Generated `lib/l10n/app_localizations_*.dart` | e.g. 962+ | Same invite URL string per locale. |
| `android/app/src/main/AndroidManifest.xml` | 45 | App Link host `YOUR_API_HOST`, pathPrefix `/invite/`. |
| `asset_pack_service.dart` | 37–38, 95–96, 126 | `$baseUrl/static/game/...` — follows API base. |

---

## 3. API keys, ad IDs, DSNs, signing

### 3.1 Public-by-design (not repo secrets)

| Item | File | Lines | Note |
|------|------|-------|------|
| Firebase Android API key | `android/app/google-services.json` (generated locally or in CI; not committed) | — | After download from Firebase, `current_key` is a client identifier; **restrict** by app/package in Google Cloud (`cat_poe/docs/firebase_fork_setup.md`). |
| AdMob **application** ID | `AndroidManifest.xml` | 55–57 | `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` (replace with your AdMob app ID) — required in client; not a server secret. |
| Google **test** ad unit IDs | `lib/services/ad_service.dart` | 34–35, 43–47, 56–57, 65–69 | Official test units `ca-app-pub-3940256099942544/...` when `kDebugMode` or when server config missing (see risk below). |

### 3.2 Dynamic / server-side (not embedded as fixed secrets in Dart)

| Item | Location | Note |
|------|----------|------|
| Coin explorer API key | `wallet_provider.dart` 60–67 | Read from `AdminConfig.coinExplorerApiKey` via API (backend must not expose to public clients — aligned with backend `PublicAdminConfigResponse`). |
| OAuth / bot tokens in `AdminConfig` model | `lib/models/admin_config.dart` 22–35, 160–171 | Parsed if present in JSON; official app should receive **sanitized** public config only. |

### 3.3 Signing (local only — good)

| Item | File | Lines |
|------|------|-------|
| Release signing | `android/app/build.gradle.kts` | 13–17, 47–55, 60–66 | Reads `android/key.properties`; throws if missing for release. **Do not commit** keystore or `key.properties`. |

---

## 4. Debug toggles, test hooks, logging

| Location | Lines | Finding |
|----------|-------|---------|
| `ad_service.dart` | 15–17 | `debugRewardGateAdOverride` — test-only; ensure tests don’t ship a non-null override in release builds (default `null`). |
| `ad_service.dart` | 31–36, 53–58 | `kDebugMode` → Google test ad units (correct). |
| `api_service.dart` | 77, 220 | Header `X-Client-Env: debug` vs `release` — backend can branch verification behavior. |
| `logger_service.dart` | 4–18 | `developer.log` for all builds — can leak operational detail; **patched** to reduce `info`/`warning` in release. |
| `link_service.dart` | 23, 35, 44 | `debugPrint` for deep links — **patched** to `kDebugMode` only. |
| `asset_pack_service.dart` | 79, 98, 138, 158 | `debugPrint` — throttled to debug-only in patch (see diff). |
| `main.dart` | 30 | `debugPrint` Firebase init error — acceptable (no stack in release tree-shake nuance). |
| `signup_screen.dart` | 75, 93 | Referrer `debugPrint` — patch to `kDebugMode`. |

**WebView:** No `webview_flutter` usage found in audited paths.

---

## 5. Deep links

| Mechanism | File | Lines |
|-----------|------|-------|
| Custom scheme | `AndroidManifest.xml` | 32–37 | `yourapp://invite` |
| Verified App Link | `AndroidManifest.xml` | 40–46 | `https://YOUR_API_HOST/invite/` |
| Runtime handling | `link_service.dart` | 34–46 | Parses `/invite/` path segments |

**Human verify:** Digital Asset Links file on `YOUR_API_HOST` matches package `YOUR_APPLICATION_ID` and signing cert (Play App Signing).

---

## 6. Release hardening checklist (verified in tree)

| Check | Evidence |
|-------|----------|
| R8 minify | `build.gradle.kts` 68 `isMinifyEnabled = true` |
| Shrink resources | 69 `isShrinkResources = true` |
| ProGuard rules file | **Added** `android/app/proguard-rules.pro` + `proguardFiles` in release |
| `debuggable` in release | Not set `true` on `<application>` in main manifest (default false for release build type) |
| Cleartext traffic | Not enabled in manifest |
| `MainActivity` exported | `true` (11–12) — required for launcher; minimize other exported components |

---

## 7. Risks and recommendations (prioritized)

### High

1. **Release builds could use Google *test* ad units** if `androidAdUnitId` / `iosAdUnitId` from config are empty (`ad_service.dart` 41–47, 63–69). Impacts revenue and SSV expectations; treat as **misconfiguration** risk.
2. **Single production API host** in code and share links ties all open-source forks to your infra unless they change defines/sources (`api_service.dart`, `app_en.arb`, manifests, many `app_localizations_*.dart`).

### Medium

3. **`AdminConfig` Dart model** still includes fields for bot/X secrets (`admin_config.dart` 22–35). Harmless if JSON never contains them; confusing for auditors — consider a `PublicAdminConfig` model or code-generated split.
4. **`allowBackup` default** may allow backup of app data; confirm policy and set `android:allowBackup="false"` if required.
5. **No `network_security_config`** pinning; acceptable per many threat models; document if you add pinning later.

### Low

6. **Comments in manifest** said “test ID” while value is a **production**-style AdMob app ID (`AndroidManifest.xml` 53–57) — **comment fixed** in patch.
7. **`google-services.json` second client** with an invalid or duplicate `package_name` (historical audits found mis-registered clients) — verify Firebase console hygiene (human).

---

## 8. Env / config matrix

See **Section 9** in this file (dedicated matrix below).

---

## 9. Configuration matrix: dev / staging / prod

| Concern | Local dev (typical) | Staging (suggested) | Production (Play) |
|---------|---------------------|---------------------|-------------------|
| **API base** | `--dart-define=API_BASE_URL=http://10.0.2.2:8000` (Android emu) or `http://127.0.0.1:8000` | `--dart-define=API_BASE_URL=https://staging.example.com` | Default from `app_config.dart` / `--dart-define` override |
| **Flutter mode** | `flutter run` (debug) | `flutter run --release` or profile against staging | `flutter build appbundle --release` |
| **Ads** | `kDebugMode` → Google test units | Release + server config with **non-test** ad unit IDs from staging AdMob | Release + production ad units from backend public config |
| **Firebase** | Same or separate `google-services.json` for dev Firebase project | Staging Firebase project | Production Firebase project |
| **Signing** | Debug key | Optional internal keystore | Play App Signing + upload key in CI secret |
| **Deep links** | `adb` / manual links | Staging host + asset links file | Production host in manifest + verified links |
| **Client env header** | `X-Client-Env: debug` | Use release build against staging to send `release` if desired | `release` |

There is **no** `productFlavors` in Gradle today; adding `staging` / `prod` flavors would be a larger change.

---

## 10. Patches applied (summary)

1. **`api_service.dart` / `app_config.dart`** — `API_BASE_URL` via `--dart-define`; see current `AppConfig.apiBaseUrl` (audit-era snapshot may differ from `HEAD`).
2. **`logger_service.dart`** — `info` / `warning` no-op when `kReleaseMode`; **`error` still logs** (for visibility until a crash reporter is wired).
3. **`ad_service.dart`** — Non-debug: if server ad unit id is missing, log `LoggerService.error` then fall back to Google test units (same behavior as before, but visible in logs).
4. **`link_service.dart`**, **`asset_pack_service.dart`**, **`signup_screen.dart`** — gate `debugPrint` with `kDebugMode` where patched.
5. **`android/app/build.gradle.kts`** — `proguardFiles(..., "proguard-rules.pro")` for release.
6. **`android/app/proguard-rules.pro`** — new file with common Flutter / Gson keeps.
7. **`AndroidManifest.xml`** — accurate comment for AdMob meta-data.

---

## 11. Human verification: Play Console / Firebase / GitHub

### Google Play Console

- [ ] App signing: Play App Signing enabled; upload key stored only in secure CI / local.
- [ ] **Integrity API** / Play Integrity (if used server-side) matches package `YOUR_APPLICATION_ID`.
- [ ] Store listing, data safety, and ad ID declarations match actual SDK usage (AdMob, etc.).
- [ ] Internal / closed testing tracks use the correct **applicationId** and signing cert for App Links if tested early.

### Firebase

- [ ] Restrict **API keys** in Google Cloud Console (Android app restriction by package + SHA-1/256).
- [ ] Remove or fix erroneous Firebase Android clients (e.g. invalid `package_name` entries in `google-services.json`).
- [ ] FCM / Analytics: confirm no debug-only endpoints in production server keys (server keys stay server-side).

### GitHub / repo

- [ ] `.gitignore` excludes `android/key.properties`, `*.jks`, `*.keystore` (verify under `cat_poe/android/.gitignore`).
- [ ] No **service account JSON** or **Play API private keys** in the repo.
- [ ] Document for contributors: `API_BASE_URL` dart-define, replacing `google-services.json`, and using their own AdMob app ID in manifest for forks.

---

*Re-audit after adding flavors, WebView, certificate pinning, or new network endpoints.*
