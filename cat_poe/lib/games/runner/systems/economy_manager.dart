/// Tracks in-game economy: coins collected, score, and distance.
/// This is NOT a Flame Component — it's a plain data holder accessed by the game and HUD.
class EconomyManager {
  int coinsCollected = 0;
  int score = 0;
  int distanceMeters = 0;

  /// 1 coin = 1 catoshi
  int get catoshiEarned => coinsCollected;

  void collectCoin() {
    coinsCollected++;
    score += 10;
  }

  void addScore(int points) {
    score += points;
  }

  void reset() {
    coinsCollected = 0;
    score = 0;
    distanceMeters = 0;
  }
}


