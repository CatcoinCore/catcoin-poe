# Firebase & Google Mobile Ads — fork / self-host setup (Android)

The Catcoin PoE app uses **Firebase Core** on Android (`Firebase.initializeApp()` in `lib/main.dart`). The Android Gradle plugin expects **`android/app/google-services.json`**.

### Repository policy (fork safety)

| File | In git? |
|------|--------|
| **`google-services.json.example`** | **Yes** — safe placeholders only. |
| **`google-services.json`** | **No** — listed in `cat_poe/.gitignore` so real project IDs and keys are not pushed by default. |

Upstream maintainers and CI should **generate or inject** `google-services.json` at build time (local copy, or a CI step that writes the file from a protected secret).

## 1. Quick start

```bash
cd cat_poe/android/app
cp google-services.json.example google-services.json
```

Edit **`google-services.json`** — do not commit it. The reliable approach is to **download** the file from the Firebase Console (Project settings → Your apps → Android app) after registering the app below. That overwrites placeholders with real `project_number`, `mobilesdk_app_id`, and `current_key`.

## 2. Package name (applicationId)

The Flutter/Android app uses:

| Setting | Value |
|---------|--------|
| `applicationId` / namespace | **`org.catcoin.cat`** in this repository (`android/app/build.gradle.kts`). Forks must use **the same string** in Firebase and Gradle, or change **both** together. |

In Firebase Console, add an **Android** app whose **Android package name** matches your app’s **`applicationId`** exactly (for this repo’s default, that is `org.catcoin.cat`).

Forks that change `applicationId` must:

1. Register a **new** Android app in **their** Firebase project with the **new** package name.  
2. Download the new **`google-services.json`**.  
3. Align **Google Cloud API key restrictions** (below) with the new package and signing certificates.

## 3. SHA-1 / SHA-256 fingerprints

Required for some Google Play services integrations and for **restricting** the client API key.

Add fingerprints in Firebase:

**Project settings → Your apps → Android app → Add fingerprint**

Include at least:

| Certificate | When |
|-------------|------|
| **Debug keystore** | Local `flutter run` / debug builds (default debug signing). |
| **Upload / release keystore** | Play App Signing: add **both** upload key and **App signing key** SHA-1/256 from Play Console if Google hosts signing. |

Obtain local SHA-1 (debug example):

```bash
cd cat_poe/android
# Windows (adjust path to your Java keytool)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## 4. API key restrictions (Google Cloud Console)

The `current_key` inside `google-services.json` is a **client** key shipped in the app. It is **not** a server secret, but it can be **abused** for quota/cost if left unrestricted.

1. Open [Google Cloud Console](https://console.cloud.google.com/) → select the Firebase-linked project.  
2. **APIs & Services → Credentials** → find the **Android key** (often named like “Android key (auto created by Firebase)”).  
3. **Application restrictions** → **Android apps** → add **package name** `org.catcoin.cat` (or your fork’s id) and each **SHA-1** you use.  
4. **API restrictions** → restrict to APIs you actually need (e.g. Firebase-related APIs, not unrestricted “Google Cloud APIs” unless required).

Rotate the key in Console if a copy was ever committed publicly without restrictions.

## 5. AdMob application ID (AndroidManifest)

Release builds declare the AdMob **application** ID in:

`android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`

Forks publishing under a **different** AdMob account must replace this `meta-data` value with their **own** app ID from [AdMob](https://admob.google.com/) (format `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy`).

Per-banner / per-interstitial **unit IDs** can also come from:

- Your backend **admin config** (`androidAdUnitId` / `iosAdUnitId`), and/or  
- **`--dart-define`** values documented in `docs/BUILD_RUNBOOK.md` (`ADMOB_ANDROID_*`).

## 6. Gitleaks / CI

The repository allowlists **`google-services.json.example`** only. Real **`google-services.json`** is **gitignored** so it is not scanned as a committed secret in CI.

**GitHub Actions example:** before `flutter build`, decode a base64-encoded secret into the app directory (store the secret in **Actions secrets**, not in the repo):

```yaml
- run: echo "${{ secrets.GOOGLE_SERVICES_JSON_B64 }}" | base64 -d > android/app/google-services.json
```

(Adjust `base64 -d` / `base64 --decode` per runner OS.)

## 7. iOS (optional)

This doc is Android-focused. If you add iOS Firebase, register the iOS bundle ID in Firebase and add **`GoogleService-Info.plist`** (also gitignored in typical OSS setups; use an `.example` pattern mirroring Android).

## See also

- `docs/BUILD_RUNBOOK.md` — dev / staging / prod Flutter commands  
- `docs/security/mobile_config_hardening.md` (repo `docs/security/`) — broader mobile security notes  
