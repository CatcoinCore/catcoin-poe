import 'package:flutter/material.dart';
import '../services/game_service.dart';

/// State management for the CatCoin Runner game integration.
class GameProvider extends ChangeNotifier {
  GameProvider({GameService? service}) : _service = service ?? GameService();

  final GameService _service;

  /// When true, [fetchStatus] and [startSession] skip the network (e.g. widget tests).
  static bool debugStubGameNetwork = false;

  String? _sessionToken;
  bool _isLoading = false;
  String? _error;
  int? _lastReward;
  GameBoostAward? _lastGameBoostAward;

  // History
  List<Map<String, dynamic>> _history = [];
  int _totalCatoshiEarned = 0;

  // Game Status
  Map<String, GameStatusItem> _statusMap = {};

  // Getters
  String? get sessionToken => _sessionToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get lastReward => _lastReward;
  GameBoostAward? get lastGameBoostAward => _lastGameBoostAward;
  List<Map<String, dynamic>> get history => _history;
  int get totalCatoshiEarned => _totalCatoshiEarned;
  Map<String, GameStatusItem> get statusMap => _statusMap;

  /// Start a new game session with the backend
  Future<bool> startSession() async {
    if (debugStubGameNetwork) {
      _isLoading = false;
      _error = null;
      _lastReward = null;
      _lastGameBoostAward = null;
      _sessionToken = 'debug-stub-session';
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _error = null;
    _lastReward = null;
    _lastGameBoostAward = null;
    notifyListeners();

    try {
      final response = await _service.startSession();
      _sessionToken = response['session_token'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit game results to the backend for validation + reward
  Future<bool> submitScore({
    required int score,
    required int coinsCollected,
    int distanceMeters = 0,
    String gameType = "RUNNER",
  }) async {
    if (_sessionToken == null) {
      _error = 'Failed to reward catoshi. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (debugStubGameNetwork) {
        _lastReward = coinsCollected;
        _lastGameBoostAward = null;
        _sessionToken = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final response = await _service.submitScore(
        sessionToken: _sessionToken!,
        score: score,
        coinsCollected: coinsCollected,
        distanceMeters: distanceMeters,
        gameType: gameType,
      );
      _lastReward = response['reward_catoshi'] ?? 0;
      _lastGameBoostAward = _parseGameBoostAward(response);
      _sessionToken = null; // Session consumed
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Extract clean error message from Exception: message
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch game history from the backend
  Future<void> fetchHistory() async {
    try {
      final response = await _service.getHistory();
      _history = List<Map<String, dynamic>>.from(response['sessions'] ?? []);
      _totalCatoshiEarned = response['total_catoshi_earned'] ?? 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch current game status (plays left, cooldowns)
  Future<void> fetchStatus() async {
    if (debugStubGameNetwork) {
      _statusMap = {
        'SUDOKU': GameStatusItem(
          gameType: 'SUDOKU',
          playCount: 0,
          canPlay: true,
        ),
        'MINER': GameStatusItem(
          gameType: 'MINER',
          playCount: 0,
          maxGames: 15,
          canPlay: true,
          reward: 75,
        ),
      };
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.getStatus();
      final List<dynamic> games = response['games'] ?? [];
      _statusMap = {
        for (var g in games)
          g['game_type']: GameStatusItem.fromJson(g)
      };
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear session state (e.g., on exit)
  void clearSession() {
    _sessionToken = null;
    _lastReward = null;
    _lastGameBoostAward = null;
    _error = null;
  }

  static GameBoostAward? _parseGameBoostAward(Map<String, dynamic> response) {
    if (response['game_boost_awarded'] != true) return null;
    final p = response['game_boost_percentage'];
    final d = response['game_boost_duration_minutes'];
    if (p == null || d == null) return null;
    return GameBoostAward(
      percentage: (p as num).toDouble(),
      durationMinutes: (d as num).toInt(),
    );
  }
}

/// Inventory game boost returned from POST /game/submit when awarded.
class GameBoostAward {
  const GameBoostAward({
    required this.percentage,
    required this.durationMinutes,
  });

  final double percentage;
  final int durationMinutes;
}

class GameStatusItem {
  final String gameType;
  final int playCount;
  final int? maxGames;
  final DateTime? cooldownUntil;
  final bool canPlay;
  final int? reward;

  GameStatusItem({
    required this.gameType,
    required this.playCount,
    this.maxGames,
    this.cooldownUntil,
    required this.canPlay,
    this.reward,
  });

  factory GameStatusItem.fromJson(Map<String, dynamic> json) {
    return GameStatusItem(
      gameType: json['game_type'],
      playCount: json['play_count'],
      maxGames: json['max_games'],
      cooldownUntil: json['cooldown_until'] != null ? DateTime.parse(json['cooldown_until']) : null,
      canPlay: json['can_play'],
      reward: json['reward'],
    );
  }
}


