import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/tunnel_miner_models.dart';
import 'miner_world.dart';
import 'tunnel_miner_field_graphics.dart';

/// Flame host for Tunnel Miner — delegates simulation to [MinerWorld].
class CatcoinTunnelMinerGame extends FlameGame
    with HasKeyboardHandlerComponents, TapCallbacks {
  CatcoinTunnelMinerGame({Random? random}) : mine = MinerWorld(random: random);

  final MinerWorld mine;
  VoidCallback? onRunEnded;

  bool _endedNotified = false;

  /// Bumps each time the run ends so the result overlay state resets between rounds.
  int resultOverlayEpoch = 0;

  /// Drives HUD rebuilds while playing so energy/score stay live with the simulation.
  final ValueNotifier<int> hudRevision = ValueNotifier(0);

  /// Limits keyboard dig spam when the OS emits repeat KeyDownEvents.
  double _keyboardDigCooldown = 0;

  static const double cell = 36;
  static const int visibleRows = 15;

  static double get fieldWidth => cell * MinerWorld.cols;

  static double get fieldHeight => cell * visibleRows;

  @override
  Color backgroundColor() => const Color(0xFF0D1117);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final worldSize = Vector2(fieldWidth, fieldHeight);
    camera.viewfinder.visibleGameSize = worldSize;
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(worldSize.x / 2, worldSize.y / 2);
    await world.add(_MinerFieldView(mine: mine));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final worldSize = Vector2(fieldWidth, fieldHeight);
    camera.viewfinder.visibleGameSize = worldSize;
    camera.viewfinder.position = Vector2(worldSize.x / 2, worldSize.y / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _keyboardDigCooldown = max(0, _keyboardDigCooldown - dt);
    if (mine.phase == TunnelRunPhase.playing) {
      mine.updateSimulation(dt);
      hudRevision.value++;
    }
    if (mine.phase == TunnelRunPhase.ended && !_endedNotified) {
      _endedNotified = true;
      resultOverlayEpoch++;
      overlays.add('Result');
      onRunEnded?.call();
    }
  }

  void notifyIntroDismissed() {
    mine.beginPlaying();
    overlays.remove('Intro');
    overlays.add('Hud');
  }

  void pauseRun() {
    mine.pause();
    pauseEngine();
    overlays.add('Pause');
  }

  void resumeRun() {
    mine.resume();
    resumeEngine();
    overlays.remove('Pause');
  }

  /// After a rewarded round, start a fresh descent without the intro card.
  void beginFreshRunAfterPlayAgain() {
    _endedNotified = false;
    mine.restart();
    overlays
      ..clear()
      ..add('Hud');
    mine.beginPlaying();
    resumeEngine();
  }

  /// Maps pointer position into the centered mine rectangle and dispatches move/dig.
  void dispatchMineTap(Vector2 localPosition) {
    if (mine.phase != TunnelRunPhase.playing) return;

    final fw = fieldWidth;
    final fh = fieldHeight;
    final ox = (size.x - fw) * 0.5;
    final oy = (size.y - fh) * 0.5;
    final x = localPosition.x - ox;
    final y = localPosition.y - oy;

    if (x < 0 || x >= fw || y < 0 || y >= fh) {
      return;
    }

    if (x < fw * 0.28) {
      mine.tryMoveLeft();
    } else if (x > fw * 0.72) {
      mine.tryMoveRight();
    } else {
      mine.tryDig();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (mine.phase != TunnelRunPhase.playing) {
      return super.onKeyEvent(event, keysPressed);
    }
    if (event is! KeyDownEvent) {
      return super.onKeyEvent(event, keysPressed);
    }

    final isDigKey = event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.keyS;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      mine.tryMoveLeft();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      mine.tryMoveRight();
      return KeyEventResult.handled;
    }
    if (isDigKey) {
      if (_keyboardDigCooldown > 0) {
        return KeyEventResult.handled;
      }
      _keyboardDigCooldown = 0.14;
      mine.tryDig();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) {
    dispatchMineTap(event.localPosition);
  }
}

class _MinerFieldView extends PositionComponent {
  _MinerFieldView({required this.mine}) : super(anchor: Anchor.topLeft);

  final MinerWorld mine;
  double _animT = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2.zero();
    size = Vector2(
      CatcoinTunnelMinerGame.fieldWidth,
      CatcoinTunnelMinerGame.fieldHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cell = CatcoinTunnelMinerGame.cell;
    final rows = CatcoinTunnelMinerGame.visibleRows;
    final pr = mine.playerRow;
    final startRow = (pr - 6).clamp(0, 1 << 30);

    final fieldRect = Offset.zero & Size(size.x, size.y);
    final scrollN = mine.grid.length <= 1
        ? 0.0
        : (startRow / (mine.grid.length - 1)).clamp(0.0, 1.0);

    TunnelMinerFieldGraphics.paintDepthBackdrop(
      canvas: canvas,
      bounds: fieldRect,
      scrollNormalized: scrollN,
    );
    TunnelMinerFieldGraphics.paintGridLines(canvas, fieldRect, cell);

    for (var vis = 0; vis < rows; vis++) {
      final r = startRow + vis;
      if (r < 0 || r >= mine.grid.length) continue;
      for (var c = 0; c < MinerWorld.cols; c++) {
        final rect =
            Rect.fromLTWH(c * cell + 0.5, vis * cell + 0.5, cell - 1, cell - 1);
        final t =
            (r == pr && c == mine.playerCol) ? TileKind.air : mine.grid[r][c];
        TunnelMinerFieldGraphics.paintTile(
          canvas: canvas,
          kind: t,
          rect: rect,
          lavaPulse: _animT,
          row: r,
          col: c,
        );
      }
    }

    if (pr >= startRow && pr < startRow + rows) {
      final vis = pr - startRow;
      final rect = Rect.fromLTWH(
        mine.playerCol * cell + 3,
        vis * cell + 3,
        cell - 7,
        cell - 7,
      );
      TunnelMinerFieldGraphics.paintPlayer(canvas, rect);
    }
  }
}
