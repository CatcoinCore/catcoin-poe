import 'package:flutter/material.dart';
import '../models/admin_config.dart';
import '../models/mission.dart';
import '../models/whats_new_release.dart';
import '../services/admin_service.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService(ApiService());

  AdminConfig? _config;
  bool _isLoading = false;
  String? _error;

  AdminConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WhatsNewRelease>? _whatsNewReleases;
  bool _whatsNewLoading = false;
  String? _whatsNewError;

  List<WhatsNewRelease>? get whatsNewReleases => _whatsNewReleases;
  bool get whatsNewLoading => _whatsNewLoading;
  String? get whatsNewError => _whatsNewError;

  Map<String, dynamic>? _selectedUserStats;
  Map<String, dynamic>? get selectedUserStats => _selectedUserStats;

  Map<String, dynamic>? _selectedUserDetails;
  Map<String, dynamic>? get selectedUserDetails => _selectedUserDetails;

  Future<void> fetchWhatsNew({String languageCode = 'en'}) async {
    _whatsNewLoading = true;
    _whatsNewError = null;
    notifyListeners();

    try {
      _whatsNewReleases =
          await _adminService.getWhatsNew(languageCode: languageCode);
    } catch (e) {
      _whatsNewError = e.toString();
      LoggerService.error('Fetch what\'s new failed', e);
    } finally {
      _whatsNewLoading = false;
      notifyListeners();
    }
  }

  /// Public config (no bot tokens / OAuth / explorer key). Safe for any logged-in user.
  Future<void> fetchConfig({String languageCode = 'en'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await _adminService.getConfig(languageCode: languageCode);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch config failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Full admin_config row; requires admin. Use before editing secret fields (bot, X, explorer).
  Future<void> fetchFullAdminConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await _adminService.getAdminConfig();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch full admin config failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateConfig(AdminConfig newConfig) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await _adminService.updateConfig(newConfig);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Update config failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mission Management
  List<Mission> _missions = [];
  List<Mission> get missions => _missions;

  Future<void> fetchMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _adminService.getMissions();
      _missions = data.map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch missions failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMission(Map<String, dynamic> missionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.createMission(missionData);
      await fetchMissions(); // Refresh list
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Create mission failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMission(
      String code, Map<String, dynamic> missionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateMission(code, missionData);
      await fetchMissions(); // Refresh list
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Update mission failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMission(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteMission(code);
      await fetchMissions(); // Refresh list
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Delete mission failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // User Management
  List<dynamic> _users = [];
  List<dynamic> get users => _users;

  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  int _summaryTotalUsers = 0;
  int _summaryActiveUsers = 0;
  int _summaryInactiveUsers = 0;
  int get summaryTotalUsers => _summaryTotalUsers;
  int get summaryActiveUsers => _summaryActiveUsers;
  int get summaryInactiveUsers => _summaryInactiveUsers;

  bool _hasMoreUsers = true;
  bool get hasMoreUsers => _hasMoreUsers;
  int _currentUserPage = 0;
  final int _userLimit = 50;

  Future<void> fetchUsers(
      {String? search,
      bool loadMore = false,
      bool? filterSuspicious,
      bool? filterAdmin,
      String activityStatus = 'all'}) async {
    if (loadMore && !_hasMoreUsers) return;
    if (loadMore && _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // If not loading more, reset state
      if (!loadMore) {
        _currentUserPage = 0;
        _users = [];
        _hasMoreUsers = true;
      }

      final data = await _adminService.getUsers(
        search: search,
        skip: _currentUserPage * _userLimit,
        limit: _userLimit,
        filterSuspicious: filterSuspicious,
        filterAdmin: filterAdmin,
        activityStatus: activityStatus,
      );

      final List<dynamic> newUsers = data['users'] as List<dynamic>;
      _totalUsers = data['total_count'] as int;
      _hasMoreUsers = data['has_more'] as bool;
      final summary = data['activity_summary'];
      if (summary is Map<String, dynamic>) {
        _summaryTotalUsers = (summary['total_users'] as num?)?.toInt() ?? 0;
        _summaryActiveUsers = (summary['active_users'] as num?)?.toInt() ?? 0;
        _summaryInactiveUsers = (summary['inactive_users'] as num?)?.toInt() ?? 0;
      }

      if (loadMore) {
        _users.addAll(newUsers);
      } else {
        _users = newUsers;
      }

      _currentUserPage++;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch users failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> pingInactiveUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await _adminService.pingInactiveUsers();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Ping inactive users failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetUserMissions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.resetUserMissions(userId);
      // Optional: Refresh user list or show success
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Reset missions failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetUserMining(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.resetUserMining(userId);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Reset mining failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a user's email as verified server-side and refresh the local
  /// detail snapshot. Returns the API response so the UI can show
  /// "already verified" vs "verified just now" feedback.
  Future<Map<String, dynamic>> activateUserEmail(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.activateUserEmail(userId);
      // Reflect the new verified state without forcing the screen to
      // round-trip through the full user-list fetch.
      if (_selectedUserDetails != null &&
          _selectedUserDetails!['id'] == userId) {
        _selectedUserDetails!['email_verified'] = true;
      }
      return result;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Activate user email failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Individual User Missions
  List<Mission> _userMissions = [];
  List<Mission> get userMissions => _userMissions;

  Future<void> fetchUserMissions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _adminService.getUserMissions(userId);
      _userMissions = data.map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch user missions failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetIndividualMission(String userId, String missionCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.resetUserMission(userId, missionCode);
      await fetchUserMissions(userId); // Refresh list
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Reset individual mission failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserStats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUserStats = await _adminService.getUserStats(userId);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch user stats failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUserDetails = await _adminService.getUserDetails(userId);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Fetch user details failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postTweet(String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.postTweet(text);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Post tweet failed', e);
      rethrow; // Rethrow to let UI handle success/snackbar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _adminService.updateUser(userId, data);
      _selectedUserDetails = updatedUser;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Update user failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> generateBonusCodes(double amount, int count) async {
    try {
      return await _adminService.generateBonusCodes(amount, count);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Awards monthly podium badges via admin API (global, regional, games) for [year]/[month] (UTC).
  Future<Map<String, dynamic>> awardMonthlyPodium({
    required int year,
    required int month,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _adminService.awardMonthlyPodium(year: year, month: month);
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Award monthly podium failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


