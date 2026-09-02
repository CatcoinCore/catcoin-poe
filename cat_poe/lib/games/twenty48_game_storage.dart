import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kTwenty48PrefsKey = 'cat_poe_twenty48_save_v1';

class Twenty48SavedGame {
  static const int currentSchema = 1;

  Twenty48SavedGame({
    required this.schemaVersion,
    required this.nextTileId,
    required this.score,
    required this.bestTile,
    required this.hasReachedTarget,
    required this.rewardGranted,
    required this.isGameOver,
    required this.grid,
  });

  final int schemaVersion;
  final int nextTileId;
  final int score;
  final int bestTile;
  final bool hasReachedTarget;
  final bool rewardGranted;
  final bool isGameOver;

  /// Each cell is `null` or `{'id': int, 'value': int}`.
  final List<List<Map<String, int>?>> grid;

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'nextId': nextTileId,
        'score': score,
        'bestTile': bestTile,
        'hasReachedTarget': hasReachedTarget,
        'rewardGranted': rewardGranted,
        'isGameOver': isGameOver,
        'grid': [
          for (final row in grid)
            [
              for (final cell in row)
                cell == null ? null : {'id': cell['id']!, 'value': cell['value']!},
            ],
        ],
      };

  static Twenty48SavedGame? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map<String, dynamic>) return null;
      final schema = m['schema'];
      if (schema is! int || schema != Twenty48SavedGame.currentSchema) {
        return null;
      }

      final nextId = m['nextId'];
      final score = m['score'];
      final bestTile = m['bestTile'];
      if (nextId is! int || score is! int || bestTile is! int) return null;

      final gridRaw = m['grid'];
      if (gridRaw is! List || gridRaw.length != 4) return null;

      final grid = <List<Map<String, int>?>>[];
      for (final rowRaw in gridRaw) {
        if (rowRaw is! List || rowRaw.length != 4) return null;
        final row = <Map<String, int>?>[];
        for (final cell in rowRaw) {
          if (cell == null) {
            row.add(null);
            continue;
          }
          if (cell is! Map) return null;
          final id = cell['id'];
          final value = cell['value'];
          if (id is! int || value is! int) return null;
          row.add({'id': id, 'value': value});
        }
        grid.add(row);
      }

      return Twenty48SavedGame(
        schemaVersion: schema,
        nextTileId: nextId,
        score: score,
        bestTile: bestTile,
        hasReachedTarget: m['hasReachedTarget'] == true,
        rewardGranted: m['rewardGranted'] == true,
        isGameOver: m['isGameOver'] == true,
        grid: grid,
      );
    } catch (_) {
      return null;
    }
  }

  /// Basic sanity check before restoring into play.
  bool validate({required int gridSize}) {
    if (grid.length != gridSize) return false;
    var maxId = 0;
    var recomputedBest = 0;
    for (final row in grid) {
      if (row.length != gridSize) return false;
      for (final cell in row) {
        if (cell == null) continue;
        final id = cell['id']!;
        final value = cell['value']!;
        if (id <= 0 || value <= 0) return false;
        if (value & (value - 1) != 0) return false;
        maxId = maxId > id ? maxId : id;
        recomputedBest = recomputedBest > value ? recomputedBest : value;
      }
    }
    if (nextTileId <= maxId) return false;
    if (bestTile != recomputedBest) return false;
    return true;
  }
}

class Twenty48GameStorage {
  Twenty48GameStorage._();

  static Future<void> save(Twenty48SavedGame game) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTwenty48PrefsKey, jsonEncode(game.toJson()));
  }

  static Future<Twenty48SavedGame?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kTwenty48PrefsKey);
    if (s == null || s.isEmpty) return null;
    return Twenty48SavedGame.tryDecode(s);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kTwenty48PrefsKey);
  }
}
