import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../models/admin_config.dart';
import '../models/whats_new_release.dart';
import '../services/logger_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  /// Public: release notes for the What's New screen (stored on `admin_config`, not bundled in app).
  Future<List<WhatsNewRelease>> getWhatsNew({String languageCode = 'en'}) async {
    try {
      final response = await _apiService.get(
        '/v1/config/whats-new',
        queryParameters: {'lang': languageCode},
      ) as Map<String, dynamic>;
      final releases = response['releases'];
      if (releases is! List) return [];
      return releases
          .whereType<Map<String, dynamic>>()
          .map(WhatsNewRelease.fromJson)
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch what\'s new', e);
      rethrow;
    }
  }

  /// Public subset (no bot tokens / third-party secrets). Use for normal app features, e.g. wallet.
  Future<AdminConfig> getConfig({String languageCode = 'en'}) async {
    try {
      final response = await _apiService.get(
        '/v1/config/',
        queryParameters: {'lang': languageCode},
      );
      return AdminConfig.fromJson(response);
    } catch (e) {
      LoggerService.error('Failed to fetch public config', e);
      if (kDebugMode && ApiService.baseUrl.contains('10.0.2.2')) {
        LoggerService.warning(
          'API base is 10.0.2.2 (Android emulator → host only). On a physical '
          'USB device it will time out. Use either: '
          '(1) flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:18080 '
          '(Docker default host port), or '
          '(2) adb reverse tcp:18080 tcp:18080 then '
          '--dart-define=API_BASE_URL=http://127.0.0.1:18080. '
          'See cat_poe/docs/BUILD_RUNBOOK.md.',
        );
      }
      rethrow;
    }
  }

  /// Full config for admin UI; requires authenticated admin (Bearer token).
  Future<AdminConfig> getAdminConfig() async {
    try {
      final response = await _apiService.get('/v1/admin/config');
      return AdminConfig.fromJson(response);
    } catch (e) {
      LoggerService.error('Failed to fetch admin config', e);
      rethrow;
    }
  }

  Future<AdminConfig> updateConfig(AdminConfig config) async {
    try {
      final response = await _apiService.put(
        '/v1/admin/config',
        body: config.toJson(),
      );
      return AdminConfig.fromJson(response);
    } catch (e) {
      LoggerService.error('Failed to update admin config', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getMissions() async {
    try {
      final response = await _apiService.get('/v1/admin/missions/');
      return response as List<dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch missions', e);
      rethrow;
    }
  }

  Future<void> createMission(Map<String, dynamic> missionData) async {
    try {
      await _apiService.post(
        '/v1/admin/missions/',
        body: missionData,
      );
    } catch (e) {
      LoggerService.error('Failed to create mission', e);
      rethrow;
    }
  }

  Future<void> updateMission(
      String code, Map<String, dynamic> missionData) async {
    try {
      await _apiService.put(
        '/v1/admin/missions/$code',
        body: missionData,
      );
    } catch (e) {
      LoggerService.error('Failed to update mission', e);
      rethrow;
    }
  }

  Future<void> deleteMission(String code) async {
    try {
      await _apiService.delete('/v1/admin/missions/$code');
    } catch (e) {
      LoggerService.error('Failed to delete mission', e);
      rethrow;
    }
  }

  // User Management
  Future<Map<String, dynamic>> getUsers(
      {int skip = 0,
      int limit = 50,
      String? search,
      bool? filterSuspicious,
      bool? filterAdmin,
      String activityStatus = 'all'}) async {
    try {
      String query = 'skip=$skip&limit=$limit';
      query += '&activity_status=$activityStatus';
      if (search != null && search.isNotEmpty) {
        query += '&search=$search';
      }
      if (filterSuspicious != null) {
        query += '&suspicious=$filterSuspicious';
      }
      if (filterAdmin != null) {
        query += '&is_admin=$filterAdmin';
      }
      final response = await _apiService.get('/v1/admin/users?$query');
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch users', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> pingInactiveUsers() async {
    try {
      final response =
          await _apiService.post('/v1/admin/users/ping-inactive');
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to ping inactive users', e);
      rethrow;
    }
  }

  Future<void> resetUserMissions(String userId) async {
    try {
      await _apiService.post('/v1/admin/users/$userId/reset-missions');
    } catch (e) {
      LoggerService.error('Failed to reset user missions', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getUserMissions(String userId) async {
    try {
      final response =
          await _apiService.get('/v1/admin/users/$userId/missions');
      return response as List<dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch user missions', e);
      rethrow;
    }
  }

  Future<void> resetUserMission(String userId, String missionCode) async {
    try {
      await _apiService.delete('/v1/admin/users/$userId/missions/$missionCode');
    } catch (e) {
      LoggerService.error('Failed to reset user mission', e);
      rethrow;
    }
  }

  Future<void> resetUserMining(String userId) async {
    try {
      await _apiService.post('/v1/admin/users/$userId/reset-mining');
    } catch (e) {
      LoggerService.error('Failed to reset user mining', e);
      rethrow;
    }
  }

  /// Manually mark a user's email as verified (admin support flow when the
  /// user can't receive their activation code). Returns the response payload
  /// so the caller can branch on `already_verified`.
  Future<Map<String, dynamic>> activateUserEmail(String userId) async {
    try {
      final response =
          await _apiService.post('/v1/admin/users/$userId/activate-email');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      LoggerService.error('Failed to activate user email', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getSuspiciousActivity(String userId) async {
    try {
      final response =
          await _apiService.get('/v1/admin/users/$userId/suspicious-activity');
      return response as List<dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch suspicious activity', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await _apiService.get('/v1/admin/users/$userId');
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch user details', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _apiService.get('/v1/admin/users/$userId/stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to fetch user stats', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postTweet(String text) async {
    try {
      final response = await _apiService.post(
        '/v1/admin/x/post',
        body: {'text': text},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to post tweet', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(
        '/v1/admin/users/$userId',
        body: data,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to update user', e);
      rethrow;
    }
  }

  Future<List<dynamic>> generateBonusCodes(double amount, int count) async {
    try {
      final response = await _apiService.post(
        '/v1/admin/bonus/generate',
        body: {'amount': amount, 'count': count},
      );
      return response as List<dynamic>;
    } catch (e) {
      LoggerService.error('Failed to generate bonus codes', e);
      rethrow;
    }
  }

  /// Grants monthly podium [UserBadge]s (global, regional, games) for the given UTC calendar month.
  Future<Map<String, dynamic>> awardMonthlyPodium({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/admin/leaderboard/award-monthly-podium',
        body: {'year': year, 'month': month},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to award monthly podium badges', e);
      rethrow;
    }
  }
}


