import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';

/// Coin Magnet pickup â€” attracts nearby coins to the player for a duration.
class MagnetPickup extends RectangleComponent with CollisionCallbacks {
  final RunnerGame gameRef;
  bool _collected = false;
  double _pulseTime = 0;

  MagnetPickup({
    required this.gameRef,
    required Vector2 position,
  }) : super(
          size: Vector2(24, 24),
          position: position,
          paint: Paint()..color = const Color(0xFFFFD600), // Bright yellow
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    // Horseshoe magnet shape â€” two prongs
    add(RectangleComponent(
      size: Vector2(6, 16),
      position: Vector2(4, 4),
      paint: Paint()..color = const Color(0xFFD32F2F), // Red prong
    ));
    add(RectangleComponent(
      size: Vector2(6, 16),
      position: Vector2(14, 4),
      paint: Paint()..color = const Color(0xFF1565C0), // Blue prong
    ));
    // Bridge across top
    add(RectangleComponent(
      size: Vector2(16, 5),
      position: Vector2(4, 2),
      paint: Paint()..color = const Color(0xFF9E9E9E), // Grey bridge
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    position.x -= gameRef.scrollSpeed * dt;

    // Pulse glow
    _pulseTime += dt;
    final pulse = 0.7 + 0.3 * ((_pulseTime * 2.5) % 1.0);
    paint.color = Color.lerp(
      const Color(0xFFFFD600),
      const Color(0xFFFFF176),
      pulse,
    )!;

    if (position.x < -30) {
      removeFromParent();
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    gameRef.powerupSystem.activateMagnet();
    removeFromParent();
  }
}


