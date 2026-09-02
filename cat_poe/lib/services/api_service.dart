import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/auth_api_responses.dart';
import 'logger_service.dart';

/// HTTP error from the API with a status code (thrown by [ApiService] on non-2xx).
class ApiHttpException implements Exception {
  ApiHttpException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Network or server error while trying to refresh the session (do not clear tokens).
class ApiTransientBackendException implements Exception {
  const ApiTransientBackendException([this.message = 'Could not reach the server to refresh your session']);

  final String message;

  @override
  String toString() => message;
}

enum _RefreshOutcome { success, noSession, authRejected, transientError }

/// Backend returned 409 with [error_code] SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION.
class SocialIdChangeRequiresConfirmationException implements Exception {
  SocialIdChangeRequiresConfirmationException({
    required this.platforms,
    required this.message,
  });

  final List<String> platforms;
  final String message;

  @override
  String toString() => message;
}

/// Maps a non-success HTTP status and body to the same exceptions as [ApiService].
Never throwApiFailureForStatusAndBody(int statusCode, String rawBody) {
  String errorMessage = 'Request failed with status: $statusCode';
  try {
    if (rawBody.isNotEmpty) {
      final body = jsonDecode(rawBody);
      if (statusCode == 409 &&
          body is Map &&
          body['detail'] is Map) {
        final d = body['detail'] as Map<String, dynamic>;
        if (d['error_code'] == 'SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION') {
          final raw = d['platforms'];
          final platforms = raw is List
              ? raw.map((e) => e.toString()).toList()
              : <String>[];
          final msg = d['user_message'] is String
              ? d['user_message'] as String
              : '';
          throw SocialIdChangeRequiresConfirmationException(
            platforms: platforms,
            message: msg.isNotEmpty
                ? msg
                : 'Changing this social ID will remove your current reward until the new ID is verified. Do you want to continue?',
          );
        }
      }
      if (body is Map && body.containsKey('detail')) {
        final detail = body['detail'];
        errorMessage =
            detail is String ? detail : jsonEncode(detail);
      }
    }
  } on SocialIdChangeRequiresConfirmationException {
    rethrow;
  } catch (_) {
    // Fallback to default message if body is not JSON
  }
  throw ApiHttpException(statusCode: statusCode, message: errorMessage);
}

class ApiService {
  /// Single in-flight refresh for the whole app — avoids refresh-token rotation races
  /// when many requests see 401 at once (multiple [ApiService] instances share this).
  static Future<_RefreshOutcome>? _refreshInFlight;

  /// Debug without `API_BASE_URL`: Android emulator → [AppConfig.debugDefaultApiBaseUrl]
  /// (default `http://10.0.2.2:18080` to match local Docker `BACKEND_HOST_PORT`).
  /// iOS Simulator / desktop / web → `http://127.0.0.1:18080`.
  /// Override anytime: `--dart-define=API_BASE_URL=http://host:port`
  static String get baseUrl {
    if (!kDebugMode) {
      return AppConfig.apiBaseUrl;
    }
    if (AppConfig.hasExplicitApiBaseUrl || AppConfig.useProductionApiInDebug) {
      return AppConfig.apiBaseUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppConfig.apiBaseUrl;
    }
    // return AppConfig.apiBaseUrl;
    return 'http://127.0.0.1:18080';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _installationId;

  Future<String?> get _accessToken async =>
      await _storage.read(key: 'access_token');
  Future<String?> get _refreshToken async =>
      await _storage.read(key: 'refresh_token');

  Future<String> _getInstallationId() async {
    if (_installationId != null) return _installationId!;

    String? storedId = await _storage.read(key: 'installation_id');
    if (storedId == null) {
      storedId = const Uuid().v4();
      await _storage.write(key: 'installation_id', value: storedId);
      LoggerService.info('Generated new Installation ID: $storedId');
    }
    _installationId = storedId;
    return _installationId!;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    LoggerService.info('Tokens saved securely');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    LoggerService.info('Tokens cleared');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessToken;
    final deviceId = await _getInstallationId();
    return {
      'Content-Type': 'application/json',
      'X-Client-Env': kDebugMode ? 'debug' : 'release',
      'X-App-Env': AppConfig.appEnvLabel,
      'X-Device-ID': deviceId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns true if a new access (and refresh) token pair was stored.
  Future<bool> refreshAccessToken() async {
    final outcome = await _serializedRefreshAccessToken();
    return outcome == _RefreshOutcome.success;
  }

  Future<_RefreshOutcome> _serializedRefreshAccessToken() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }
    _refreshInFlight = _performRefreshAccessToken().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<_RefreshOutcome> _performRefreshAccessToken() async {
    final refreshToken = await _refreshToken;
    if (refreshToken == null) {
      LoggerService.info('No refresh token available');
      return _RefreshOutcome.noSession;
    }

    try {
      final url = Uri.parse('$baseUrl/auth/refresh');
      LoggerService.info('Refreshing access token...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          LoggerService.error('Token refresh: response is not a JSON object');
          await clearTokens();
          return _RefreshOutcome.authRejected;
        }
        try {
          final tokens = AuthTokenPayload.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          await saveTokens(tokens.accessToken, tokens.refreshToken);
        } on FormatException catch (e) {
          LoggerService.error('Token refresh: invalid payload', e);
          await clearTokens();
          return _RefreshOutcome.authRejected;
        }
        LoggerService.info('Access token refreshed successfully');
        return _RefreshOutcome.success;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        LoggerService.error('Token refresh rejected: ${response.statusCode}');
        await clearTokens();
        return _RefreshOutcome.authRejected;
      }

      if (response.statusCode >= 500 && response.statusCode <= 599) {
        LoggerService.error('Token refresh server error: ${response.statusCode}');
        return _RefreshOutcome.transientError;
      }

      LoggerService.error('Token refresh failed: ${response.statusCode}');
      return _RefreshOutcome.transientError;
    } catch (e) {
      LoggerService.error('Token refresh error: $e');
      return _RefreshOutcome.transientError;
    }
  }

  Future<http.Response> _maybeRefreshAndRetry401(
    http.Response firstResponse,
    Future<http.Response> Function(Map<String, String> hdr) redo,
  ) async {
    var response = firstResponse;
    if (response.statusCode != 401) return response;

    LoggerService.info('Got 401, attempting token refresh...');
    final outcome = await _serializedRefreshAccessToken();
    if (outcome == _RefreshOutcome.success) {
      LoggerService.info('Retrying request with new token...');
      response = await redo(await _headers());
      return response;
    }
    if (outcome == _RefreshOutcome.transientError) {
      throw const ApiTransientBackendException();
    }
    return response;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParameters,
        },
      );
    }
    LoggerService.info('GET: $uri');

    var response = await http.get(uri, headers: await _headers());
    response = await _maybeRefreshAndRetry401(
      response,
      (h) => http.get(uri, headers: h),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    LoggerService.info('POST: $url');

    var response = await http.post(
      url,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    response = await _maybeRefreshAndRetry401(
      response,
      (h) => http.post(
            url,
            headers: h,
            body: body != null ? jsonEncode(body) : null,
          ),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    LoggerService.info('PUT: $url');

    var response = await http.put(
      url,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    response = await _maybeRefreshAndRetry401(
      response,
      (h) => http.put(
            url,
            headers: h,
            body: body != null ? jsonEncode(body) : null,
          ),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    LoggerService.info('DELETE: $url');

    var response = await http.delete(url, headers: await _headers());
    response = await _maybeRefreshAndRetry401(
      response,
      (h) => http.delete(url, headers: h),
    );

    return _handleResponse(response);
  }

  Future<dynamic> postForm(String endpoint, {Map<String, String>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    LoggerService.info('POST FORM: $url');

    final deviceId = await _getInstallationId();

    Future<Map<String, String>> formHeaders() async {
      final token = await _accessToken;
      return {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Device-ID': deviceId,
        'X-Client-Env': kDebugMode ? 'debug' : 'release',
        'X-App-Env': AppConfig.appEnvLabel,
        if (token != null) 'Authorization': 'Bearer $token',
      };
    }

    var response = await http.post(
      url,
      headers: await formHeaders(),
      body: body,
    );

    if (response.statusCode == 401) {
      LoggerService.info('Got 401, attempting token refresh...');
      final outcome = await _serializedRefreshAccessToken();
      if (outcome == _RefreshOutcome.success) {
        LoggerService.info('Retrying request with new token...');
        response = await http.post(
          url,
          headers: await formHeaders(),
          body: body,
        );
      } else if (outcome == _RefreshOutcome.transientError) {
        throw const ApiTransientBackendException();
      }
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    LoggerService.info('Response: ${response.statusCode}');

    // Explicitly handle 204 No Content
    if (response.statusCode == 204) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // Fallback if not JSON (e.g. simple string response)
        LoggerService.info('Could not parse JSON response: $e');
        return response.body;
      }
    } else {
      LoggerService.error('Request failed: ${response.body}');
      throwApiFailureForStatusAndBody(
        response.statusCode,
        response.body,
      );
    }
  }

  // --- Auth & Profile ---
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await put(
      '/auth/users/me/password',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  // --- Leaderboard & Awards ---

  Future<List<dynamic>> getGlobalLeaderboard({int limit = 50}) async {
    final response = await get('/leaderboard/global?limit=$limit');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> getReferredLeaderboard({int limit = 10}) async {
    final response = await get('/leaderboard/referred?limit=$limit');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> getMyBadges() async {
    final response = await get('/leaderboard/badges');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> getRegionalLeaderboard({int limit = 20}) async {
    final response = await get('/leaderboard/regional?limit=$limit');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> getPreviousMonthLeaders({int limit = 3}) async {
    final response = await get('/leaderboard/previous-month?limit=$limit');
    if (response != null && response is List) {
      return response;
    }
    return [];
  }

  /// Authenticated: global + regional (your country) + per-game top 3 for previous month.
  Future<Map<String, dynamic>> getPreviousMonthSummary({int? year, int? month}) async {
    final q = (year != null && month != null) ? '?year=$year&month=$month' : '';
    final response = await get('/leaderboard/previous-month/summary$q');
    if (response is Map<String, dynamic>) return response;
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateShowcaseBadges(List<String> badgeIds) async {
    final response = await put(
      '/auth/users/me/showcase-badges',
      body: {'badge_ids': badgeIds},
    );
    if (response is Map<String, dynamic>) return response;
    return Map<String, dynamic>.from(response as Map);
  }
}


