import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/diagnostic_service.dart';
import '../services/logger_service.dart';
import '../services/pending_referral_storage.dart';
import '../services/profile_service.dart';
import '../models/auth_api_responses.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DiagnosticService _diagnostic = DiagnosticService();

  User? _user;
  String? _profileImagePath;
  bool _isLoading = false;
  String? _error;
  /// True when tokens exist but loading `/auth/users/me` failed for a recoverable reason.
  bool _sessionResumeBlocked = false;
  bool _resumeProfileLoading = false;

  User? get user => _user;
  String? get profileImagePath => _profileImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get sessionResumeBlocked => _sessionResumeBlocked;
  bool get isResumeProfileLoading => _resumeProfileLoading;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.postForm('/auth/login', body: {
        'username': username,
        'password': password,
        'grant_type': 'password',
      });

      final tokens = AuthTokenPayload.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      await _apiService.saveTokens(tokens.accessToken, tokens.refreshToken);

      await fetchUserProfile();
      // Invite links are for new signups; do not keep a stale code after logging in.
      await PendingReferralStorage.clear();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Login failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password,
      {String? referralCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _apiService.post('/auth/signup', body: {
        'email': email,
        'password': password,
        if (referralCode != null) 'referred_by': referralCode,
      });
      if (raw is! Map) {
        throw FormatException('Unexpected signup response (expected JSON object)');
      }
      SignupAck.fromJson(Map<String, dynamic>.from(raw));
      // TODO(play-age-signals): call AgeSignalService here once the Android
      // Play Age Signals API leaves beta (currently v0.0.3). Result feeds
      // PUT /auth/users/me/age-signal (not yet wired). See
      // docs/play_age_signals_integration.md.
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Signup failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final response = await _apiService.post('/auth/verify-email', body: {
        'email': email,
        'code': code,
      });

      final tokens = AuthTokenPayload.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      await _apiService.saveTokens(tokens.accessToken, tokens.refreshToken);

      // Fetch user profile
      await fetchUserProfile();

      LoggerService.info('Email verified successfully');
    } catch (e) {
      LoggerService.error('Email verification failed', e);
      rethrow;
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      await _apiService.post('/auth/resend-code', body: {
        'email': email,
      });
      LoggerService.info('Verification code resent');
    } catch (e) {
      LoggerService.error('Failed to resend code', e);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.post('/auth/forgot-password', body: {'email': email});
      LoggerService.info('Forgot password requested');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Forgot password failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.post('/auth/reset-password',
          body: {'email': email, 'code': code, 'new_password': newPassword});
      // Backend revokes all refresh tokens; clear local session.
      await _apiService.clearTokens();
      _user = null;
      _profileImagePath = null;
      _sessionResumeBlocked = false;
      notifyListeners();
      LoggerService.info('Password reset successfully');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Reset password failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.changePassword(oldPassword, newPassword);
      LoggerService.info('Password changed successfully');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Change password failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Try to revoke refresh token on backend
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await _apiService.post('/auth/logout', body: {
          'refresh_token': refreshToken,
        });
      }
    } catch (e) {
      LoggerService.info('Logout API call failed: $e');
    }

    // Clear local tokens regardless
    await _apiService.clearTokens();
    _user = null;
    _profileImagePath = null;
    _sessionResumeBlocked = false;
    notifyListeners();
  }

  /// Captures a diagnostic report and flips ``_sessionResumeBlocked`` when
  /// the failure occurred on a cold boot (no in-memory user yet).
  ///
  /// The report carries the underlying error class + message + optional
  /// HTTP status so operators can spot 503-storms vs. parse errors vs.
  /// network drops at a glance. We don't send the access token, refresh
  /// token, password fields, or the user's email.
  void _applyRecoverableProfileFailureIfCold({
    required String fingerprint,
    Object? error,
    int? httpStatus,
  }) {
    // Capture is fire-and-forget; the screen flip below must not wait on
    // SharedPreferences / network. Errors inside the service are swallowed
    // by the service itself.
    unawaited(_diagnostic.capture(ClientErrorReport(
      fingerprint: fingerprint,
      userId: null, // user is by definition not loaded here
      appVersion: '', // enriched inside DiagnosticService
      platform: '', // enriched inside DiagnosticService
      screen: 'auth_wrapper',
      errorClass: error?.runtimeType.toString(),
      errorMessage: error?.toString(),
      httpStatus: httpStatus,
    )));

    if (_user != null) {
      notifyListeners();
      return;
    }
    _sessionResumeBlocked = true;
    notifyListeners();
  }

  /// After a transient error at startup, retry loading the profile without clearing tokens.
  Future<void> retryResumeSession() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      _sessionResumeBlocked = false;
      notifyListeners();
      return;
    }
    _resumeProfileLoading = true;
    _sessionResumeBlocked = false;
    _error = null;
    notifyListeners();
    try {
      await fetchUserProfile();
    } finally {
      _resumeProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiService.get('/auth/users/me');
      try {
        _user = User.fromJson(response);
      } catch (e) {
        LoggerService.error('Invalid user profile payload', e);
        _applyRecoverableProfileFailureIfCold(
          fingerprint: 'auth_profile_parse_failed',
          error: e,
        );
        return;
      }

      _sessionResumeBlocked = false;

      // Load local profile image path
      if (_user != null) {
        _profileImagePath = await ProfileService.getProfileImagePath(_user!.id);
        _syncDeviceCountry(_user!);
      }

      // The /auth/users/me round-trip just succeeded, so the server is
      // reachable. Flush any reports queued during a previous outage —
      // strictly fire-and-forget so it never blocks the UI.
      unawaited(_diagnostic.flushPending());

      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to fetch user profile', e);
      if (e is ApiHttpException) {
        final c = e.statusCode;
        if (c == 401 || c == 403) {
          await logout();
          return;
        }
        _applyRecoverableProfileFailureIfCold(
          fingerprint: 'auth_resume_http_$c',
          error: e,
          httpStatus: c,
        );
        return;
      }
      if (e is ApiTransientBackendException) {
        _applyRecoverableProfileFailureIfCold(
          fingerprint: 'auth_resume_transient',
          error: e,
        );
        return;
      }
      _applyRecoverableProfileFailureIfCold(
        fingerprint: 'auth_resume_unknown',
        error: e,
      );
    }
  }

  Future<void> _syncDeviceCountry(User user) async {
    try {
      String? deviceCountry;
      String? countrySource;

      // Retry the entire chain until we get a valid public IP (not 172.18.0.4)
      const maxOverallAttempts = 6;
      for (int attempt = 0; attempt < maxOverallAttempts && deviceCountry == null; attempt++) {
        if (attempt > 0) await Future.delayed(const Duration(seconds: 4));

        // --- API 1: geojs.io ---
        deviceCountry = await _tryGeoJs();
        if (deviceCountry != null) { countrySource = 'IP'; break; }

        // --- API 2: ip-api.com ---
        deviceCountry = await _tryIpApi();
        if (deviceCountry != null) { countrySource = 'IP'; break; }

        // --- API 3: iplocation.net ---
        deviceCountry = await _tryIpLocation();
        if (deviceCountry != null) { countrySource = 'IP'; break; }

        LoggerService.info('All IP APIs returned no valid country on attempt $attempt, retrying...');
      }

      // --- Last resort: device locale ---
      if (deviceCountry == null) {
        deviceCountry = ui.PlatformDispatcher.instance.locale.countryCode;
        if (deviceCountry != null) countrySource = 'LOCALE';
      }

      // Update when: country changed OR was never properly set (no source = emulator/bug artifact)
      final shouldUpdate = deviceCountry != null &&
          (user.country != deviceCountry || user.countrySource == null);
      if (shouldUpdate) {
        await _apiService.put('/auth/users/me/profile', body: {
          'country': deviceCountry,
          'country_source': countrySource,
        });
        final refreshed = await _apiService.get('/auth/users/me');
        _user = User.fromJson(refreshed);
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('Failed to sync device country', e);
    }
  }

  static const _internalIps = {'172.18.0.4', '127.0.0.1', '::1', '0.0.0.0'};

  Future<String?> _tryGeoJs() async {
    try {
      final resp = await http
          .get(Uri.parse('https://get.geojs.io/v1/ip/country.json'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final ip = data is List ? data[0]['ip'] : data['ip'];
        if (_internalIps.contains(ip)) return null;
        final country = data is List ? data[0]['country'] : data['country'];
        return (country as String?)?.isNotEmpty == true ? country : null;
      }
    } catch (e) {
      LoggerService.error('geojs.io failed', e);
    }
    return null;
  }

  Future<String?> _tryIpApi() async {
    try {
      final resp = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=status,query,countryCode'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (_internalIps.contains(data['query'] as String?)) return null;
        if (data['status'] == 'success' && data['countryCode'] != null) {
          return data['countryCode'] as String;
        }
      }
    } catch (e) {
      LoggerService.error('ip-api.com failed', e);
    }
    return null;
  }

  Future<String?> _tryIpLocation() async {
    try {
      final resp = await http
          .get(Uri.parse('https://api.iplocation.net/?cmd=ip-country'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final ip = data['ip'] as String?;
        if (_internalIps.contains(ip)) return null;
        if (data['response_code'] == '200' && data['country_code2'] != null) {
          return data['country_code2'] as String;
        }
      }
    } catch (e) {
      LoggerService.error('iplocation.net failed', e);
    }
    return null;
  }


  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.put('/auth/users/me/profile', body: data);
      _user = User.fromJson(response);
      LoggerService.info('Profile updated successfully');
    } on SocialIdChangeRequiresConfirmationException {
      rethrow;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to update profile', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetSocialId(String platform) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/users/me/reset-social-id',
        body: {'platform': platform},
      );
      // Wait to fetch the new user profile state
      await fetchUserProfile();
      LoggerService.info('Social ID reset successfully: ${response['message']}');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to reset social ID', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReferredBy(String referralCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/auth/users/me/referred-by',
        body: {'referral_code': referralCode},
      );
      _user = User.fromJson(response);
      LoggerService.info('Referred by code updated successfully');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to update referred by code', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setProfileImage(String path) async {
    if (_user == null) return;

    try {
      await ProfileService.saveProfileImagePath(_user!.id, path);
      _profileImagePath = path;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to save profile image path', e);
    }
  }

  Future<void> skipProfileSetup() async {
    if (_user == null) return;
    await ProfileService.setProfileSetupCompleted(_user!.id);
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Clean up local image
      if (_user != null) {
        await ProfileService.removeProfileImage(_user!.id);
      }

      await _apiService.delete('/auth/users/me');
      await _apiService.clearTokens();
      _user = null;
      _profileImagePath = null;
      _sessionResumeBlocked = false;
      LoggerService.info('Account deleted successfully');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to delete account', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuth() async {
    _sessionResumeBlocked = false;
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      await fetchUserProfile();
    }
  }

  /// Pin up to 6 earned badges on the profile (order preserved).
  Future<void> updateShowcaseBadges(List<String> badgeIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.updateShowcaseBadges(badgeIds);
      _user = User.fromJson(response);
      LoggerService.info('Showcase badges updated');
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to update showcase badges', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


