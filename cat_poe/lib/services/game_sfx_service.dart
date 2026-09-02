import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../games/runner/systems/asset_pack_service.dart';

/// Short UI/game effects served from the downloadable **mini** pack
/// (`GET …/static/game/mini/…`, see [MiniGameAssetService]).
enum GameSfx {
  tap('sounds/tap.mp3'),
  softTap('sounds/soft_tap.mp3'),
  slide('sounds/slide.mp3'),
  bump('sounds/bump.mp3'),
  merge('sounds/merge.mp3'),
  win('sounds/win.mp3'),
  lose('sounds/lose.mp3'),
  coin('sounds/coin.mp3');

  const GameSfx(this.packRelativePath);
  final String packRelativePath;
}

/// Low-latency SFX for mini-games (does **not** include Cat Runner).
/// Audio files are **not** bundled in the app; they load from disk after
/// [MiniGameAssetService] downloads the `mini` pack.
class GameSfxService {
  GameSfxService._();
  static final GameSfxService instance = GameSfxService._();

  MiniGameAssetService? _miniPack;

  final List<AudioPlayer> _pool = [];
  var _poolIndex = 0;
  var _warmedUp = false;

  /// Called from [MiniGameAssetService] construction so playback can resolve paths.
  void attachMiniGamePack(MiniGameAssetService service) {
    _miniPack = service;
  }

  /// Prepare a small player pool (no files loaded).
  Future<void> warmup() async {
    if (_warmedUp) return;
    _warmedUp = true;
    try {
      const n = 8;
      for (var i = 0; i < n; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GameSfxService warmup failed: $e\n$st');
      }
      _warmedUp = false;
    }
  }

  /// Fire-and-forget; no-op if the mini pack is not downloaded yet.
  void play(GameSfx sfx, {double volume = 1.0}) {
    unawaited(_playAsync(sfx, volume.clamp(0.0, 1.0)));
  }

  Future<void> _playAsync(GameSfx sfx, double volume) async {
    if (kIsWeb) return;

    final mini = _miniPack;
    if (mini == null || !mini.isReady) return;

    try {
      await warmup();
      if (_pool.isEmpty) return;

      final path = mini.getAssetPath(sfx.packRelativePath);
      final file = File(path);
      if (!await file.exists()) return;

      final p = _pool[_poolIndex++ % _pool.length];
      await p.stop();
      await p.setVolume(volume);
      await p.play(DeviceFileSource(path));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GameSfx play ${sfx.packRelativePath}: $e\n$st');
      }
    }
  }
}
