import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'parallax_background.dart';

/// Scrolling ground platform at the bottom of the screen.
/// Updates colors based on the current world theme.
class Ground extends RectangleComponent with HasGameReference<RunnerGame> {
  static const double groundHeight = 60.0;

  WorldTheme _currentTheme = WorldTheme.cryptoCity;
  late RectangleComponent _topEdge;
  late RectangleComponent _dirtLayer;
  final List<RectangleComponent> _tufts = [];

  Ground({required RunnerGame gameRef})
      : super(
          size: Vector2(RunnerGame.worldWidth, groundHeight),
          position: Vector2(0, RunnerGame.worldHeight - groundHeight),
          paint: Paint()..color = themeMap[WorldTheme.cryptoCity]!.groundSurface,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final td = themeMap[_currentTheme]!;

    // Top edge
    _topEdge = RectangleComponent(
      size: Vector2(RunnerGame.worldWidth, 4),
      position: Vector2(0, 0),
      paint: Paint()..color = _darken(td.groundSurface),
    );
    add(_topEdge);

    // Dirt layer
    _dirtLayer = RectangleComponent(
      size: Vector2(RunnerGame.worldWidth, groundHeight * 0.6),
      position: Vector2(0, groundHeight * 0.4),
      paint: Paint()..color = td.groundDirt,
    );
    add(_dirtLayer);

    // Grass / surface tufts
    for (double x = 0; x < RunnerGame.worldWidth; x += 30) {
      final tuft = RectangleComponent(
        size: Vector2(4, 8),
        position: Vector2(x, -6),
        paint: Paint()..color = td.groundTuft,
      );
      add(tuft);
      _tufts.add(tuft);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final newTheme = themeForDistance(game.economyManager.distanceMeters);
    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
      _applyTheme();
    }
  }

  void _applyTheme() {
    final td = themeMap[_currentTheme]!;
    paint.color = td.groundSurface;
    _topEdge.paint.color = _darken(td.groundSurface);
    _dirtLayer.paint.color = td.groundDirt;
    for (final t in _tufts) {
      t.paint.color = td.groundTuft;
    }
  }

  Color _darken(Color c) {
    return Color.fromARGB(
      c.a.toInt(),
      (c.r * 0.7).toInt(),
      (c.g * 0.7).toInt(),
      (c.b * 0.7).toInt(),
    );
  }
}


