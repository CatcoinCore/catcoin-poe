import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kCollagePrefsKey = 'cat_poe_collage_save_v1';

/// Persisted sliding collage puzzle state.
class CollageSavedGame {
  CollageSavedGame({
    required this.schemaVersion,
    required this.tiles,
    required this.emptyIndex,
    required this.isGameOver,
    required this.isScrambled,
    required this.imageIndex,
    required this.rewardSubmitted,
  });

  static const int currentSchema = 1;

  final int schemaVersion;
  final List<int> tiles;
  final int emptyIndex;
  final bool isGameOver;
  final bool isScrambled;
  final int imageIndex;
  final bool rewardSubmitted;

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'tiles': tiles,
        'emptyIndex': emptyIndex,
        'isGameOver': isGameOver,
        'isScrambled': isScrambled,
        'imageIndex': imageIndex,
        'rewardSubmitted': rewardSubmitted,
      };

  static CollageSavedGame? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map<String, dynamic>) return null;
      final schema = m['schema'];
      if (schema is! int || schema != currentSchema) return null;
      final tilesRaw = m['tiles'];
      if (tilesRaw is! List || tilesRaw.length != 16) return null;
      final tiles = [for (final x in tilesRaw) (x as num).toInt()];
      return CollageSavedGame(
        schemaVersion: schema,
        tiles: tiles,
        emptyIndex: (m['emptyIndex'] as num).toInt(),
        isGameOver: m['isGameOver'] == true,
        isScrambled: m['isScrambled'] == true,
        imageIndex: (m['imageIndex'] as num).toInt(),
        rewardSubmitted: m['rewardSubmitted'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Tiles must be a permutation of 0..15; empty tile value is 15.
  bool validate() {
    if (tiles.length != 16) return false;
    final sorted = List<int>.from(tiles)..sort();
    for (var i = 0; i < 16; i++) {
      if (sorted[i] != i) return false;
    }
    if (emptyIndex < 0 || emptyIndex > 15) return false;
    if (tiles[emptyIndex] != 15) return false;
    if (imageIndex < 1 || imageIndex > 10) return false;
    return true;
  }
}

class CollageGameStorage {
  CollageGameStorage._();

  static Future<void> save(CollageSavedGame game) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCollagePrefsKey, jsonEncode(game.toJson()));
  }

  static Future<CollageSavedGame?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kCollagePrefsKey);
    if (s == null || s.isEmpty) return null;
    final g = CollageSavedGame.tryDecode(s);
    if (g == null || !g.validate()) return null;
    return g;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCollagePrefsKey);
  }
}
