import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'logger_service.dart';

/// Structured payload for `POST /v1/diagnostics/client-error`. Kept in sync
/// with `cat_poe_backend/schemas.py::ClientErrorReport`. All string lengths
/// match the server's caps; longer values get truncated before serialisation.
class ClientErrorReport {
  ClientErrorReport({
    required this.fingerprint,
    this.userId,
    required this.appVersion,
    required this.platform,
    this.osVersion,
    this.locale,
    this.screen,
    this.errorClass,
    this.errorMessage,
    this.httpStatus,
    this.occurredAt,
    this.breadcrumbs = const <String>[],
  });

  /// Short stable grouping key (e.g. "auth_resume_blocked"). 1..128 chars.
  final String fingerprint;
  final String? userId;
  final String appVersion;
  final String platform;
  final String? osVersion;
  final String? locale;
  final String? screen;
  final String? errorClass;
  final String? errorMessage;
  final int? httpStatus;
  final DateTime? occurredAt;
  final List<String> breadcrumbs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fingerprint': _clip(fingerprint, 128)!,
        if (userId != null) 'user_id': userId,
        'app_version': _clip(appVersion, 64)!,
        'platform': _clip(platform, 32)!,
        if (osVersion != null) 'os_version': _clip(osVersion, 128),
        if (locale != null) 'locale': _clip(locale, 32),
        if (screen != null) 'screen': _clip(screen, 128),
        if (errorClass != null) 'error_class': _clip(errorClass, 256),
        if (errorMessage != null) 'error_message': _clip(errorMessage, 2048),
        if (httpStatus != null) 'http_status': httpStatus,
        if (occurredAt != null) 'occurred_at': occurredAt!.toUtc().toIso8601String(),
        if (breadcrumbs.isNotEmpty)
          'breadcrumbs': breadcrumbs
              .map((b) => _clip(b, 256))
              .whereType<String>()
              .take(20)
              .toList(growable: false),
      };

  static ClientErrorReport fromJson(Map<String, dynamic> json) {
    return ClientErrorReport(
      fingerprint: json['fingerprint'] as String? ?? 'unknown',
      userId: json['user_id'] as String?,
      appVersion: json['app_version'] as String? ?? 'unknown',
      platform: json['platform'] as String? ?? 'unknown',
      osVersion: json['os_version'] as String?,
      locale: json['locale'] as String?,
      screen: json['screen'] as String?,
      errorClass: json['error_class'] as String?,
      errorMessage: json['error_message'] as String?,
      httpStatus: (json['http_status'] as num?)?.toInt(),
      occurredAt: json['occurred_at'] is String
          ? DateTime.tryParse(json['occurred_at'] as String)
          : null,
      breadcrumbs: (json['breadcrumbs'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }
}

String? _clip(String? value, int maxLen) {
  if (value == null) return null;
  if (value.length <= maxLen) return value;
  return value.substring(0, maxLen);
}

/// Captures unrecoverable client errors and best-effort delivers them to
/// `POST /v1/diagnostics/client-error`.
///
/// **Design constraints:**
///   - The very failure being reported may be a network failure, so this
///     service tolerates the post call hanging or failing.
///   - When the post fails, the report is persisted under
///     [_pendingPrefsKey] and re-tried on [flushPending] (which the caller
///     wires into any "we successfully reached the backend" hook).
///   - The queue is capped at [_maxPending] entries; older reports are
///     dropped to keep SharedPreferences small.
///   - Reports must not contain access tokens, refresh tokens, password
///     fields, or other user secrets. The caller is responsible for
///     sanitising what they pass in.
class DiagnosticService {
  DiagnosticService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _pendingPrefsKey = 'pending_diagnostic_reports';
  static const int _maxPending = 50;
  static const Duration _httpTimeout = Duration(seconds: 8);

  final http.Client _httpClient;

  /// Capture + best-effort send + queue-on-failure in one call.
  ///
  /// Returns true if the report reached the server (server returned 2xx);
  /// false if it was queued for retry. Either way, the call never throws —
  /// diagnostic capture is observation, not a critical path.
  Future<bool> capture(ClientErrorReport report) async {
    final enriched = await _enrich(report);
    final delivered = await _postOnce(enriched);
    if (!delivered) {
      await _enqueue(enriched);
    }
    return delivered;
  }

  /// Try to flush any queued reports. Call from a location that knows the
  /// backend is reachable (e.g. after a successful `/auth/users/me`).
  Future<void> flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_pendingPrefsKey) ?? const <String>[];
    if (raw.isEmpty) return;

    final remaining = <String>[];
    for (final json in raw) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final report = ClientErrorReport.fromJson(decoded);
        final ok = await _postOnce(report);
        if (!ok) {
          remaining.add(json);
        }
      } catch (e) {
        // Drop entries that won't decode rather than choke forever.
        LoggerService.error('DiagnosticService: dropping bad queued entry', e);
      }
    }
    await prefs.setStringList(_pendingPrefsKey, remaining);
  }

  /// Enrich a caller-supplied report with environment fields the service
  /// is best positioned to compute (app version, OS, locale, etc.).
  Future<ClientErrorReport> _enrich(ClientErrorReport report) async {
    String appVersion = report.appVersion;
    if (appVersion.isEmpty || appVersion == 'unknown') {
      appVersion = await _readAppVersion();
    }
    final platform = report.platform.isEmpty || report.platform == 'unknown'
        ? _platformLabel()
        : report.platform;
    final osVersion = report.osVersion ?? _osVersionLabel();
    final locale =
        report.locale ?? ui.PlatformDispatcher.instance.locale.toLanguageTag();
    return ClientErrorReport(
      fingerprint: report.fingerprint,
      userId: report.userId,
      appVersion: appVersion,
      platform: platform,
      osVersion: osVersion,
      locale: locale,
      screen: report.screen,
      errorClass: report.errorClass,
      errorMessage: report.errorMessage,
      httpStatus: report.httpStatus,
      occurredAt: report.occurredAt ?? DateTime.now().toUtc(),
      breadcrumbs: report.breadcrumbs,
    );
  }

  Future<bool> _postOnce(ClientErrorReport report) async {
    final url = Uri.parse('${ApiService.baseUrl}/v1/diagnostics/client-error');
    try {
      final resp = await _httpClient
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(report.toJson()),
          )
          .timeout(_httpTimeout);
      // 202 Accepted is the happy path; we also tolerate 200 for symmetry.
      if (resp.statusCode == 200 || resp.statusCode == 202) {
        return true;
      }
      if (resp.statusCode == 429) {
        // Rate-limited. Don't requeue — the server already heard from us
        // recently and re-emitting won't help.
        LoggerService.info(
          'DiagnosticService: rate-limited by server (fingerprint=${report.fingerprint})',
        );
        return true;
      }
      LoggerService.info(
        'DiagnosticService: non-2xx response ${resp.statusCode} from server',
      );
      return false;
    } catch (e) {
      // Network failure, DNS failure, TLS error — common when reporting
      // exactly the failure mode we care about. Persist for retry.
      LoggerService.info('DiagnosticService: post failed: $e');
      return false;
    }
  }

  Future<void> _enqueue(ClientErrorReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_pendingPrefsKey) ?? <String>[];
      current.add(jsonEncode(report.toJson()));
      // Drop oldest entries when the queue grows beyond the cap so we
      // never balloon SharedPreferences during a long outage.
      while (current.length > _maxPending) {
        current.removeAt(0);
      }
      await prefs.setStringList(_pendingPrefsKey, current);
    } catch (e) {
      LoggerService.error('DiagnosticService: enqueue failed', e);
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
      if (Platform.isFuchsia) return 'fuchsia';
    } catch (_) {
      // dart:io Platform is unavailable on web; kIsWeb branch covers it.
    }
    return 'unknown';
  }

  String _osVersionLabel() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String> _readAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final base = info.version;
      final build = info.buildNumber;
      return build.isEmpty ? base : '$base+$build';
    } catch (_) {
      return 'unknown';
    }
  }
}
