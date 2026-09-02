/// Tile types for the static mining grid (boulders are tracked separately).
enum TileKind {
  air,
  dirt,
  rock,
  lava,
  ore,
  exit,
}

/// High-level run lifecycle inside the Flame game.
enum TunnelRunPhase {
  intro,
  playing,
  paused,
  ended,
}

/// Why a Tunnel Miner run stopped.
enum TunnelEndReason {
  none,
  energy,
  hazard,
  /// Reached the extraction tile alive.
  extracted,
}

/// Finer cause for losses (shown on the result / map-review UI).
enum TunnelLossDetail {
  none,
  energy,
  lava,
  boulder,
}

/// Mutable stats exposed to HUD / overlays.
class TunnelMinerRunStats {
  TunnelMinerRunStats({
    required this.maxDepth,
    required this.shards,
    required this.score,
    required this.extracted,
    required this.reason,
    required this.energy,
    required this.energyMax,
    this.lossDetail = TunnelLossDetail.none,
  });

  int maxDepth;
  int shards;
  int score;
  bool extracted;
  TunnelEndReason reason;
  TunnelLossDetail lossDetail;
  int energy;
  final int energyMax;

  void resetForNewRun({
    required int energyMax,
  }) {
    maxDepth = 0;
    shards = 0;
    score = 0;
    extracted = false;
    reason = TunnelEndReason.none;
    lossDetail = TunnelLossDetail.none;
    energy = energyMax;
  }

  /// Deepest row index reached (same convention as [MinerWorld.playerRow]).
  void syncDepthFromPlayer(int playerRow) {
    if (playerRow > maxDepth) {
      maxDepth = playerRow;
    }
  }
}
