import 'package:shared_preferences/shared_preferences.dart';

/// Persists how many TicTacToe rounds completed since the last reward-gate ad.
/// Used for "every 3 games" interstitial before rewards.
class TicTacToeAdCounterStore {
  static const _key = 'tictactoe_completed_games_ad_counter';

  static Future<int> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key) ?? 0;
  }

  /// Adds one and persists. Returns the new value.
  static Future<int> incrementAndGet() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_key) ?? 0) + 1;
    await p.setInt(_key, v);
    return v;
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
