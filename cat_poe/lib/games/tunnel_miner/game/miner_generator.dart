import 'dart:math';

import '../data/tunnel_miner_models.dart';

/// Procedural row fill for Tunnel Miner.
class MinerGenerator {
  MinerGenerator(this._rng);

  final Random _rng;

  /// Fills [row] in-place for the given absolute [rowIndex] (vertical position).
  /// When [rowIndex] == [exitRow], places an [exit] tile in the center column.
  void fillRow(
    List<TileKind> row, {
    required int rowIndex,
    required int exitRow,
    int centerCol = 4,
  }) {
    // Lava is rare near the surface and ramps up with depth so early runs stay forgiving.
    final depthT = (rowIndex / 52.0).clamp(0.0, 1.0);
    final lavaChance = 0.016 + 0.074 * depthT;
    final rockStart = lavaChance + 0.17;
    final oreStart = rockStart + 0.065;

    for (var c = 0; c < row.length; c++) {
      final r = _rng.nextDouble();
      if (r < lavaChance) {
        row[c] = TileKind.lava;
      } else if (r < rockStart) {
        row[c] = TileKind.rock;
      } else if (r < oreStart) {
        row[c] = TileKind.ore;
      } else {
        row[c] = TileKind.dirt;
      }
    }
    _guaranteeWalkableLane(row);
    if (rowIndex == exitRow) {
      row[centerCol] = TileKind.exit;
    }
  }

  /// Ensures at least one of the center columns is not rock/lava so the shaft can continue.
  void _guaranteeWalkableLane(List<TileKind> row) {
    const centers = [3, 4, 5];
    var ok = false;
    for (final c in centers) {
      if (row[c] != TileKind.rock && row[c] != TileKind.lava) {
        ok = true;
        break;
      }
    }
    if (!ok) {
      row[4] = TileKind.dirt;
    }
  }
}
