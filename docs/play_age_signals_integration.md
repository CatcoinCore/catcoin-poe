# Google Play Age Signals — integration plan

Texas **SB 2420** ("App Store Accountability Act") pushes age verification down
from the platform into Google Play; the **Play Age Signals API** is the
mechanism. Catcoin needs to consume the signal at signup so it can block /
restrict accounts for users Google flags as unverified in Texas.

This document is the **plan** while we wait on the API to leave beta. The
backend column groundwork has already landed (see "Backend ready" below); the
client wiring is intentionally deferred.

## Status of the API

- **Today (May 2026):** Play Age Signals API **v0.0.3** (beta).
- **Coming weeks:** Google Play will start requiring age verification for new
  users in **Texas**; the API will return real signals for eligible Texas
  users once that flag flips.
- **Risk to early adopters:** v0.0.x is beta, so types and method names may
  shift before v1.0. That is the reason this PR ships only the backend
  groundwork — see "What we did now" — and leaves the Android / Flutter wiring
  for v1.0 or a stable signal from Google about Texas enforcement dates.

## Allowed status values

The `users.age_signal_status` column accepts the platform enum verbatim
(plus `null` for "field never touched"):

| Value | Meaning |
|---|---|
| `null` | Never recorded for this user (legacy rows, or signup before integration shipped). |
| `not_checked` | We've decided to track this user but haven't called the API yet. |
| `not_required` | Google's response: the user is not in a jurisdiction that requires verification. Proceed normally. |
| `verified` | Google's response: the user is age-verified. Proceed normally. |
| `pending` | Google has the request but the user hasn't finished verification yet. UX: show a "complete verification" prompt; backend should restrict reward / withdrawal endpoints until cleared. |
| `not_verified` | Google's response: the user must verify but hasn't. UX: block signup completion (or block withdrawals + payouts); backend should refuse reward submissions until cleared. |

## What we did now (backend groundwork)

1. **`users.age_signal_status` (VARCHAR, nullable)** and
   **`users.age_signal_checked_at` (TIMESTAMP, nullable)** on `models.User`.
2. **Auto-migrate** entries in `main.py`'s startup column-patch list so the
   columns appear automatically on next deploy.
3. **`UserResponse.age_signal_status` / `age_signal_checked_at`** in the
   Pydantic schemas so the admin UI sees the value.
4. **`AdminUserUpdate.age_signal_status`** + validator enforcing the enum.
   The PUT `/admin/users/{id}` handler stamps `age_signal_checked_at` on
   override.
5. **Admin override UI** on `admin_user_detail_screen.dart` — a popup menu
   that lets support set / clear the value while we wait on the client SDK.
6. **Privacy policy** ([privacy-policy.md](../privacy-policy.md)) updated.

## What's left to do (client wiring, when v1.0 / enforcement lands)

1. **Add the Android dependency** in `cat_poe/android/app/build.gradle.kts`:
   ```kotlin
   implementation("com.google.android.play:age-signals:<v1.0.0>")
   ```

2. **Kotlin module** (~50 LOC) under
   `cat_poe/android/app/src/main/kotlin/.../AgeSignalsPlugin.kt`:
   ```kotlin
   class AgeSignalsPlugin(...): MethodChannel.MethodCallHandler {
     override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
       when (call.method) {
         "requestAgeSignal" -> {
           AgeSignalsManager(activity).requestAgeSignal()
             .addOnSuccessListener { result.success(it.statusString) }
             .addOnFailureListener { result.error("AGE_SIGNAL_FAILED", it.message, null) }
         }
         else -> result.notImplemented()
       }
     }
   }
   ```

3. **Dart wrapper** at `cat_poe/lib/services/age_signal_service.dart`:
   ```dart
   class AgeSignalService {
     static const _channel = MethodChannel('catcoin/age_signal');
     Future<String> request() async {
       if (!Platform.isAndroid) return 'not_required';
       try {
         return await _channel.invokeMethod<String>('requestAgeSignal') ?? 'not_checked';
       } on PlatformException {
         return 'not_checked';
       }
     }
   }
   ```

4. **Signup wiring** in `cat_poe/lib/providers/auth_provider.dart` after a
   successful signup response:
   ```dart
   final status = await AgeSignalService().request();
   await _apiService.put('/auth/users/me/age-signal', body: {'status': status});
   ```
   (We need a small backend endpoint or to reuse the admin PUT — TBD when we
   wire it.)

5. **Server-side enforcement.** Add a guard helper in
   `cat_poe_backend/services/age_signal_gate.py` that raises `403` for
   `not_verified` and `pending` on the high-risk endpoints (`/wallets/...`,
   `/games/submit`, anywhere money moves). Whitelist the override field so
   admins can clear individuals.

6. **iOS:** the API is Android-only. iOS users land on `not_required`. If we
   add an iOS build, we'll need an Apple-equivalent or a content gate.

7. **Play Console:** add the API consumption to the **Data Safety** form,
   refresh the **content rating** if needed, and confirm the audience under
   "Target audience and content".

## Test plan when we wire it

- Mock Android emulator + `adb shell setprop debug.googleplay.ageSignal verified`
  (Google's debug knob); confirm signup proceeds.
- Same with `not_verified`: signup blocks, admin UI shows red badge,
  override clears.
- Backend pytest: a unit test for the `age_signal_gate` helper covering each
  enum value.

## Notes

- The status string is stored verbatim from the platform — if Google adds
  new enum values in v1.0+, the schema validator will need updating.
- `age_signal_checked_at` is meant for audit (e.g., "this admin overrode
  pending → verified on 2026-06-01"). Treat it as immutable once non-null;
  only the admin override / a fresh client call should update it.
- The signup flow may need a **brief blocking spinner** during the Android
  call. Budget ~1-2 seconds; the API is async on the platform side.

---

*Author: backend-groundwork PR (see `cat_poe_backend/models.py`,
`cat_poe_backend/schemas.py`, `cat_poe_backend/routers/admin.py`).
Client wiring is intentionally deferred per the "wait for v1.0" decision.*
