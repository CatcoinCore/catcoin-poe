import 'package:flutter_test/flutter_test.dart';

import 'package:cat_poe/games/tunnel_miner/data/tunnel_miner_score.dart';

void main() {
  group('computeTunnelMinerScore', () {
    test('combines depth, shards, and extraction bonus', () {
      expect(
        computeTunnelMinerScore(depthBlocks: 10, shards: 4, extracted: false),
        10 * 100 + 4 * 50,
      );
      expect(
        computeTunnelMinerScore(depthBlocks: 10, shards: 4, extracted: true),
        10 * 100 + 4 * 50 + 500,
      );
    });

    test('handles zero values', () {
      expect(
        computeTunnelMinerScore(depthBlocks: 0, shards: 0, extracted: false),
        0,
      );
    });
  });
}
