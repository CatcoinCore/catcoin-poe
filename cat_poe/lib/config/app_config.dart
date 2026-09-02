import 'package:flutter/foundation.dart';

/// Compile-time environment for open-source / CI builds.
///
/// Pass via `--dart-define=KEY=value` (see repo `docs/BUILD_RUNBOOK.md`).
class AppConfig {
  AppConfig._();

  /// `development` | `staging` | `production` — for logging and support only.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );

  /// Backend origin without trailing slash. Highest priority.
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// True when `API_BASE_URL` was passed via `--dart-define` (non-empty).
  static bool get hasExplicitApiBaseUrl => _apiBaseUrlFromEnv.trim().isNotEmpty;

  /// Explicit opt-in to call production API while [kDebugMode] is true.
  static const bool useProductionApiInDebug = bool.fromEnvironment(
    'USE_PRODUCTION_API_IN_DEBUG',
    defaultValue: false,
  );

  /// Allow Google’s official **test** AdMob unit IDs when not in debug and
  /// server config / dart-define units are missing. **Off by default** for release.
  static const bool allowAdmobTestFallback = bool.fromEnvironment(
    'ALLOW_ADMOB_TEST_FALLBACK',
    defaultValue: false,
  );

  // --- Optional build-time AdMob unit overrides (staging / local release testing) ---

  static const String admobAndroidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_UNIT_ID',
    defaultValue: '',
  );
  static const String admobAndroidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_UNIT_ID',
    defaultValue: '',
  );
  static const String admobIosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_UNIT_ID',
    defaultValue: '',
  );
  static const String admobIosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_UNIT_ID',
    defaultValue: '',
  );

  /// Default REST API for **debug** builds when `API_BASE_URL` is unset.
  /// Android emulator → host (matches `docker-compose.yml` default `BACKEND_HOST_PORT=18080`).
  /// Desktop / iOS simulator: [ApiService.baseUrl] uses `127.0.0.1` with the same port.
  static const String debugDefaultApiBaseUrl = String.fromEnvironment(
    'DEBUG_DEFAULT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:18080',
  );

  /// Default REST API for **release/profile** when `API_BASE_URL` is unset.
  static const String releaseDefaultApiBaseUrl = String.fromEnvironment(
    'RELEASE_DEFAULT_API_BASE_URL',
    defaultValue: 'https://poe.catcoin.in',
  );

  // Google sample ad units (safe for debug; do not rely on them in store release).
  static const String admobTestAndroidRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String admobTestAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String admobTestIosRewarded =
      'ca-app-pub-3940256099942544/1712485313';
  static const String admobTestIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  static String _normalizeBaseUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Effective API base URL (no trailing slash).
  static String get apiBaseUrl {
    final fromEnv = _apiBaseUrlFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return _normalizeBaseUrl(fromEnv);
    }
    if (kDebugMode && !useProductionApiInDebug) {
      return _normalizeBaseUrl(debugDefaultApiBaseUrl);
    }
    return _normalizeBaseUrl(releaseDefaultApiBaseUrl);
  }

  /// Label for `X-App-Env` (and similar) headers.
  static String get appEnvLabel {
    switch (appEnv.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return 'development';
      case 'stage':
      case 'staging':
        return 'staging';
      case 'prod':
      case 'production':
        return 'production';
      default:
        return kDebugMode ? 'development' : 'production';
    }
  }
}
