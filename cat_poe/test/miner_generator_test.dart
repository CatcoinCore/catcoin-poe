import 'dart:math';

import 'package:cat_poe/games/tunnel_miner/data/tunnel_miner_models.dart';
import 'package:cat_poe/games/tunnel_miner/game/miner_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shallow rows spawn less lava than deep rows', () {
    final rng = Random(42);
    final gen = MinerGenerator(rng);

    var shallowLava = 0;
    var deepLava = 0;
    const trials = 800;
    const cols = 9;

    for (var i = 0; i < trials; i++) {
      final shallow = List<TileKind>.filled(cols, TileKind.air);
      gen.fillRow(shallow, rowIndex: 2, exitRow: 999);
      shallowLava += shallow.where((t) => t == TileKind.lava).length;

      final deep = List<TileKind>.filled(cols, TileKind.air);
      gen.fillRow(deep, rowIndex: 80, exitRow: 999);
      deepLava += deep.where((t) => t == TileKind.lava).length;
    }

    expect(deepLava, greaterThan(shallowLava));
  });
}
