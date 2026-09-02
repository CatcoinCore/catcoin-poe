import 'dart:math';

import '../data/tunnel_miner_models.dart';
import '../data/tunnel_miner_score.dart';
import 'miner_generator.dart';

/// Optional audio hints from [MinerWorld] (no Flutter dependency).
enum TunnelMinerSfxKind {
  dig,
  stride,
  mineAdjacent,
  collectOre,
  runWin,
  runLose,
}

/// Grid simulation for Tunnel Miner (no rendering).
///
/// Brown dirt, gold ore, and red lava fall straight down when the cell below is
/// air. Grey rock never moves.
///
/// Mud (dirt) only falls when it is a single loose tile: if there is mud/rock
/// directly above, the upper tile holds it in place. Ore and lava still fall
/// whenever air is below.
class MinerWorld {
  MinerWorld({
    Random? random,
    int? seed,
  })  : _rng = random ?? Random(seed),
        generator = MinerGenerator(random ?? Random(seed)) {
    exitRow = 20 + _rng.nextInt(12);
    _bootstrapSurface();
  }

  final Random _rng;
  final MinerGenerator generator;
  late int exitRow;

  static const int cols = 9;
  static const int digEnergyCost = 10;
  /// Same-row grey rock takes more drill power than brown dirt when mined sideways.
  static const int lateralRockEnergyCost = digEnergyCost * 2;
  static const int lateralEnergyCost = 1;
  static const int startEnergy = 140;
  static const int oreEnergyGain = 12;

  final List<List<TileKind>> grid = [];

  int playerCol = 4;
  int playerRow = 2;
  TunnelRunPhase phase = TunnelRunPhase.intro;
  final TunnelMinerRunStats stats = TunnelMinerRunStats(
    maxDepth: 0,
    shards: 0,
    score: 0,
    extracted: false,
    reason: TunnelEndReason.none,
    energy: startEnergy,
    energyMax: startEnergy,
  );

  double _fallCooldown = 0;
  double _debrisCooldown = 0;
  static const double fallInterval = 0.14;
  static const double debrisInterval = 0.22;

  /// Wired by the presentation layer for short sound effects.
  void Function(TunnelMinerSfxKind kind)? sfxSink;

  static bool _fallsWithGravity(TileKind t) =>
      t == TileKind.dirt || t == TileKind.ore || t == TileKind.lava;

  /// Mud tile is considered held when any mud/rock is directly above it.
  bool _dirtHeldByTileAbove(int c, int r) {
    if (r <= 0) return false;
    final above = grid[r - 1][c];
    return above == TileKind.dirt || above == TileKind.rock;
  }

  void _bootstrapSurface() {
    grid.clear();
    for (var i = 0; i < 6; i++) {
      grid.add(List<TileKind>.filled(cols, TileKind.air, growable: false));
    }
    _appendGeneratedRowsThrough(playerRow + 28);
    playerCol = 4;
    playerRow = 2;
    phase = TunnelRunPhase.intro;
    stats.resetForNewRun(energyMax: startEnergy);
    _recalcScore();
  }

  void restart() {
    exitRow = 20 + _rng.nextInt(12);
    _bootstrapSurface();
  }

  void beginPlaying() {
    if (phase == TunnelRunPhase.intro) {
      phase = TunnelRunPhase.playing;
      _updateDepth();
    }
  }

  void pause() {
    if (phase == TunnelRunPhase.playing) {
      phase = TunnelRunPhase.paused;
    }
  }

  void resume() {
    if (phase == TunnelRunPhase.paused) {
      phase = TunnelRunPhase.playing;
    }
  }

  void _appendGeneratedRowsThrough(int maxRowExclusive) {
    while (grid.length < maxRowExclusive) {
      final rowIndex = grid.length;
      final row = List<TileKind>.generate(cols, (_) => TileKind.air);
      generator.fillRow(row, rowIndex: rowIndex, exitRow: exitRow);
      grid.add(row);
    }
  }

  void _endRun(
    TunnelEndReason reason, {
    TunnelLossDetail lossDetail = TunnelLossDetail.none,
  }) {
    if (phase == TunnelRunPhase.ended) return;
    phase = TunnelRunPhase.ended;
    stats.reason = reason;
    stats.extracted = reason == TunnelEndReason.extracted;
    stats.lossDetail = lossDetail;
    _recalcScore();
    if (reason == TunnelEndReason.extracted) {
      sfxSink?.call(TunnelMinerSfxKind.runWin);
    } else if (reason != TunnelEndReason.none) {
      sfxSink?.call(TunnelMinerSfxKind.runLose);
    }
  }

  void _recalcScore() {
    stats.score = computeTunnelMinerScore(
      depthBlocks: stats.maxDepth,
      shards: stats.shards,
      extracted: stats.extracted,
    );
  }

  void _updateDepth() {
    stats.syncDepthFromPlayer(playerRow);
    _recalcScore();
  }

  void _hazardCheck() {
    final t = grid[playerRow][playerCol];
    if (t == TileKind.lava) {
      _endRun(TunnelEndReason.hazard, lossDetail: TunnelLossDetail.lava);
      return;
    }
    if (t == TileKind.exit) {
      _endRun(TunnelEndReason.extracted);
    }
  }

  void _collectOreIfStanding() {
    if (grid[playerRow][playerCol] == TileKind.ore) {
      sfxSink?.call(TunnelMinerSfxKind.collectOre);
      grid[playerRow][playerCol] = TileKind.air;
      stats.shards += 1;
      stats.energy = (stats.energy + oreEnergyGain).clamp(0, stats.energyMax);
      _recalcScore();
    }
  }

  /// One bottom-to-top pass: each loose tile moves down one cell if the cell
  /// below is air (or interacts with the player in that cell).
  bool _fallingSolidsOneSweep() {
    if (phase != TunnelRunPhase.playing) return false;
    var moved = false;
    for (var c = 0; c < cols; c++) {
      for (var r = grid.length - 2; r >= 0; r--) {
        if (_tryFallFrom(c, r)) moved = true;
      }
    }
    return moved;
  }

  void _settleFallingSolidsFully() {
    final cap = (grid.length + cols + 24).clamp(8, 120);
    for (var i = 0; i < cap; i++) {
      if (!_fallingSolidsOneSweep()) break;
      if (phase != TunnelRunPhase.playing) return;
    }
    _hazardCheck();
  }

  /// Returns true if something at [c],[r] moved, was collected, or ended the run.
  bool _tryFallFrom(int c, int r) {
    if (phase != TunnelRunPhase.playing) return false;
    final t = grid[r][c];
    if (!_fallsWithGravity(t)) return false;
    final below = r + 1;
    if (below >= grid.length) {
      _appendGeneratedRowsThrough(below + 4);
    }
    if (grid[below][c] != TileKind.air) return false;

    if (t == TileKind.dirt && _dirtHeldByTileAbove(c, r)) {
      return false;
    }

    final onPlayer = c == playerCol && below == playerRow;
    if (onPlayer) {
      if (t == TileKind.ore) {
        sfxSink?.call(TunnelMinerSfxKind.collectOre);
        grid[r][c] = TileKind.air;
        stats.shards += 1;
        stats.energy = (stats.energy + oreEnergyGain).clamp(0, stats.energyMax);
        _recalcScore();
        return true;
      }
      if (t == TileKind.lava) {
        _endRun(TunnelEndReason.hazard, lossDetail: TunnelLossDetail.lava);
        return true;
      }
      if (t == TileKind.dirt) {
        _endRun(TunnelEndReason.hazard, lossDetail: TunnelLossDetail.boulder);
        return true;
      }
    }

    grid[below][c] = t;
    grid[r][c] = TileKind.air;
    return true;
  }

  /// One vertical step: fall through air; land on dirt/rock; step into ore/lava/exit.
  void _gravityStep() {
    if (phase != TunnelRunPhase.playing) return;
    final below = playerRow + 1;
    if (below >= grid.length) {
      _appendGeneratedRowsThrough(below + 8);
    }
    final t = grid[below][playerCol];
    if (t == TileKind.air) {
      playerRow = below;
      _hazardCheck();
      return;
    }
    if (t == TileKind.dirt || t == TileKind.rock) {
      _hazardCheck();
      return;
    }
    // lava, ore, exit — occupy the cell below
    playerRow = below;
    _collectOreIfStanding();
    _hazardCheck();
  }

  void tryMoveLeft() => _tryMoveHorizontal(-1);

  void tryMoveRight() => _tryMoveHorizontal(1);

  /// Move into open cells, or **mine sideways** through adjacent brown dirt / grey rock
  /// (same row) so you can reach passages that were blocked.
  void _tryMoveHorizontal(int deltaCol) {
    if (phase != TunnelRunPhase.playing) return;
    final nc = playerCol + deltaCol;
    if (nc < 0 || nc >= cols) return;
    final t = grid[playerRow][nc];
    if (t == TileKind.dirt || t == TileKind.rock) {
      _tryMineAdjacentHorizontal(nc);
      return;
    }
    if (stats.energy < lateralEnergyCost) {
      _endRun(TunnelEndReason.energy, lossDetail: TunnelLossDetail.energy);
      return;
    }
    playerCol = nc;
    stats.energy -= lateralEnergyCost;
    sfxSink?.call(TunnelMinerSfxKind.stride);
    _collectOreIfStanding();
    _updateDepth();
    _hazardCheck();
  }

  void _tryMineAdjacentHorizontal(int col) {
    final row = playerRow;
    final t = grid[row][col];
    if (t != TileKind.dirt && t != TileKind.rock) return;
    final cost = t == TileKind.rock ? lateralRockEnergyCost : digEnergyCost;
    if (stats.energy < cost) {
      _endRun(TunnelEndReason.energy, lossDetail: TunnelLossDetail.energy);
      return;
    }
    stats.energy -= cost;
    sfxSink?.call(TunnelMinerSfxKind.mineAdjacent);
    grid[row][col] = TileKind.air;
    if (t == TileKind.dirt && _rng.nextDouble() < 0.1) {
      grid[row][col] = TileKind.ore;
    }
    playerCol = col;
    _settlePlayerVertical();
    _updateDepth();
    _recalcScore();
    _settleFallingSolidsFully();
    _hazardCheck();
  }

  void tryDig() {
    if (phase != TunnelRunPhase.playing) return;
    final belowRow = playerRow + 1;
    if (belowRow >= grid.length) {
      _appendGeneratedRowsThrough(belowRow + 12);
    }
    if (stats.energy < digEnergyCost) {
      _endRun(TunnelEndReason.energy, lossDetail: TunnelLossDetail.energy);
      return;
    }
    final t = grid[belowRow][playerCol];
    if (t != TileKind.dirt) return;

    grid[belowRow][playerCol] = TileKind.air;
    stats.energy -= digEnergyCost;
    sfxSink?.call(TunnelMinerSfxKind.dig);
    if (_rng.nextDouble() < 0.12) {
      grid[belowRow][playerCol] = TileKind.ore;
    }
    _settlePlayerVertical();
    _updateDepth();
    _recalcScore();
    _settleFallingSolidsFully();
    _hazardCheck();
  }

  /// Fall through air; land on dirt/rock; fall into ore/lava/exit with collection / resolution.
  void _settlePlayerVertical() {
    while (phase == TunnelRunPhase.playing) {
      final below = playerRow + 1;
      if (below >= grid.length) {
        _appendGeneratedRowsThrough(below + 12);
      }
      final t = grid[below][playerCol];
      if (t == TileKind.air) {
        playerRow = below;
        _hazardCheck();
        continue;
      }
      if (t == TileKind.dirt || t == TileKind.rock) {
        _hazardCheck();
        return;
      }
      playerRow = below;
      _collectOreIfStanding();
      _hazardCheck();
    }
  }

  void _tickFallingSolidsAmbient() {
    if (phase != TunnelRunPhase.playing) return;
    for (var i = 0; i < 16; i++) {
      if (!_fallingSolidsOneSweep()) break;
      if (phase != TunnelRunPhase.playing) return;
    }
    _hazardCheck();
  }

  void updateSimulation(double dt) {
    if (phase != TunnelRunPhase.playing) return;
    _fallCooldown += dt;
    _debrisCooldown += dt;
    while (_fallCooldown >= fallInterval && phase == TunnelRunPhase.playing) {
      _fallCooldown -= fallInterval;
      _gravityStep();
    }
    while (_debrisCooldown >= debrisInterval && phase == TunnelRunPhase.playing) {
      _debrisCooldown -= debrisInterval;
      _tickFallingSolidsAmbient();
    }
  }
}
