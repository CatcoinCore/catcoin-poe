import '../services/api_service.dart';

/// Service for game-related API calls (mirrors pattern from other services).
class GameService {
  final ApiService _api = ApiService();

  /// POST /game/start → returns {session_id, session_token}
  Future<Map<String, dynamic>> startSession() async {
    final response = await _api.post('/game/start');
    return response;
  }

  /// POST /game/submit → validates and returns reward info
  Future<Map<String, dynamic>> submitScore({
    required String sessionToken,
    required int score,
    required int coinsCollected,
    required int distanceMeters,
    String gameType = "RUNNER",
  }) async {
    final response = await _api.post('/game/submit', body: {
      'session_token': sessionToken,
      'score': score,
      'coins_collected': coinsCollected,
      'distance_meters': distanceMeters,
      'game_type': gameType,
    });
    return response;
  }

  /// GET /game/history → returns last 20 sessions + total catoshi
  Future<Map<String, dynamic>> getHistory() async {
    final response = await _api.get('/game/history');
    return response;
  }

  /// GET /game/status → returns plays left and cooldowns
  Future<Map<String, dynamic>> getStatus() async {
    final response = await _api.get('/game/status');
    return response;
  }

  /// GET /game/leaderboard/{game_type} → returns leaders for a specific game
  Future<Map<String, dynamic>> getLeaderboard(String gameType, {int limit = 100}) async {
    final response = await _api.get('/game/leaderboard/$gameType?limit=$limit');
    return response;
  }
}


