import 'dart:async';
import 'package:flutter/material.dart';
import '../models/active_session.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../models/enhanced_stats.dart';
import '../models/user_game_boost.dart';

class MiningProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  EnhancedStats? _stats;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  DateTime? _lastFetchTime; // Track when we last fetched from server
  List<UserGameBoost> _availableGameBoosts = [];
  /// Bumped when boost-related local prefs (e.g. time-boost cooldowns) change after server-driven [fetchStats].
  int _boostLocalPrefsRevision = 0;
  /// True while [startMining] is in progress (POST + follow-up [fetchStats]).
  bool _startMiningRequestInFlight = false;

  EnhancedStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get timeLeft => _timeLeft;
  List<UserGameBoost> get availableGameBoosts => _availableGameBoosts;
  int get boostLocalPrefsRevision => _boostLocalPrefsRevision;

  /// Call after time-boost (or other) booster prefs are written so badge counts re-read storage.
  void notifyBoostLocalPrefsChanged() {
    _boostLocalPrefsRevision++;
    notifyListeners();
  }

  bool get isMining =>
      _stats?.activeSessions.isNotEmpty == true && _timeLeft.inSeconds > 0;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/stats/me');
      _stats = EnhancedStats.fromJson(response);
      _lastFetchTime = DateTime.now().toUtc();
      _updateTimer();
      await fetchAvailableGameBoosts();
    } catch (e) {
      _error = 'Service unavailable. Please try again later.';
      LoggerService.error('Failed to fetch stats', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startMining() async {
    if (_startMiningRequestInFlight) {
      return;
    }
    if (isMining) {
      return;
    }

    _startMiningRequestInFlight = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/mining/start');
      await fetchStats(); // Fetch once to get session details
    } catch (e) {
      if (e is ApiHttpException &&
          e.statusCode == 400 &&
          e.message.contains('Active base mining session already exists')) {
        // Stale [isMining] / race with server: sync instead of error.
        _error = null;
        await fetchStats();
        LoggerService.info('Start mining: already active, refreshed stats');
      } else {
        _error = 'Failed to start mining. Please try again.';
        LoggerService.error('Failed to start mining', e);
      }
    } finally {
      _startMiningRequestInFlight = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTimer() {
    _timer?.cancel();

    if (_stats?.activeSessions.isNotEmpty == true) {
      // Prefer the BASE session for timer / notification purposes. A user
      // can have multiple active sessions concurrently (BASE plus one or
      // more REFERRAL_BOOST sessions that piggy-back on referees' mining).
      // The backend used to return them in arbitrary order, so picking
      // `.first` could land on a shorter REFERRAL_BOOST — leading to a
      // premature "Mining Stopped!" local notification when the boost
      // ended even though hours of BASE remained.
      final sessions = _stats!.activeSessions;
      final primarySession = sessions.firstWhere(
        (s) => s.sessionType == 'BASE',
        // No BASE session shouldn't happen if there are any active rows,
        // but fall back to the latest end_time so we never schedule the
        // notification at a needlessly-early time.
        orElse: () => sessions.reduce(
          (a, b) => a.endTime.isAfter(b.endTime) ? a : b,
        ),
      );
      final endTime = primarySession.endTime;
      final now = DateTime.now().toUtc();

      final difference = endTime.difference(now);

      if (difference.isNegative) {
        _timeLeft = Duration.zero;
      } else {
        _timeLeft = difference;
        _startCountdown();
      }
    } else {
      _timeLeft = Duration.zero;
    }
    notifyListeners();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        _timeLeft = _timeLeft - const Duration(seconds: 1);

        // Calculate earnings increment from last fetch
        if (_stats?.activeSessions.isNotEmpty == true &&
            _lastFetchTime != null) {
          final now = DateTime.now().toUtc();

          final updatedSessions = _stats!.activeSessions.map((session) {
            final totalElapsed = now.difference(session.startTime).inSeconds;
            final elapsedSafe = totalElapsed > 0 ? totalElapsed : 0;
            final calculatedEarned =
                ((elapsedSafe * session.rewardY) ~/ session.rewardT).toDouble();

            return ActiveSession(
              id: session.id,
              sessionType: session.sessionType,
              miningFor: session.miningFor,
              yieldPercentage: session.yieldPercentage,
              startTime: session.startTime,
              endTime: session.endTime,
              totalEarned: calculatedEarned,
              rewardY: session.rewardY,
              rewardT: session.rewardT,
              referralBoostPercentage: session.referralBoostPercentage,
              timeBoostSlots: session.timeBoostSlots,
            );
          }).toList();

          // Update the sessions' earned amounts
          _stats = EnhancedStats(
            balance: _stats!.balance,
            yieldPercentage: _stats!.yieldPercentage,
            referralBoostPercentage: _stats!.referralBoostPercentage,
            activeSessions: updatedSessions,
            earningsBreakdown: _stats!.earningsBreakdown,
            totalVerifiedEarnings: _stats!.totalVerifiedEarnings,
            totalUnverifiedEarnings: _stats!.totalUnverifiedEarnings,
            availableReferrals: _stats!.availableReferrals,
          );
        }

        notifyListeners();
      } else {
        timer.cancel();
        // Session ended - fetch final stats
        fetchStats();
      }
    });
  }

  Future<void> activateBoost(String referralId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/mining/boost/$referralId');
      await fetchStats(); // Refresh to show updated boosters
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Boost activation failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> extendSession(int hours) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/mining/extend', body: {'hours': hours});
      await fetchStats(); // Refresh to show updated session end time
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Session extension failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableGameBoosts() async {
    try {
      final response = await _apiService.get('/mining/available-game-boosts');
      _availableGameBoosts = (response as List)
          .map((json) => UserGameBoost.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to fetch available game boosts', e);
    }
  }

  Future<void> activateGameBoost(String boostId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/mining/activate-game-boost', body: {'boost_id': boostId});
      await fetchStats(); // Refresh stats after activation
      await fetchAvailableGameBoosts(); // Refresh inventory
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Game boost activation failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _pingReferralsLoading = false;
  bool get pingReferralsLoading => _pingReferralsLoading;

  /// Returns server stats map (total_targets, pinged, skipped, failed).
  Future<Map<String, dynamic>> pingAllReferrals() async {
    _pingReferralsLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/referrals/ping-all');
      return Map<String, dynamic>.from(response as Map);
    } finally {
      _pingReferralsLoading = false;
      notifyListeners();
    }
  }

  Future<void> redeemSpecialBonus(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/mining/bonus/redeem', body: {'code': code});
      await fetchStats(); // Refresh balance
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Bonus redemption failed', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}


