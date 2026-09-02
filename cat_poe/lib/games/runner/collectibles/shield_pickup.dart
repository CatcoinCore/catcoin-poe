import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';

/// Shield pickup â€” grants a protective shield that absorbs one enemy hit.
class ShieldPickup extends RectangleComponent with CollisionCallbacks {
  final RunnerGame gameRef;
  bool _collected = false;
  double _pulseTime = 0;

  ShieldPickup({
    required this.gameRef,
    required Vector2 position,
  }) : super(
          size: Vector2(24, 24),
          position: position,
          paint: Paint()..color = const Color(0xFF42A5F5), // Blue
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    // Shield icon â€” inner diamond
    add(RectangleComponent(
      size: Vector2(12, 12),
      position: Vector2(6, 6),
      paint: Paint()..color = const Color(0xFF90CAF9),
    ));
    // Center dot
    add(CircleComponent(
      radius: 3,
      position: Vector2(12, 12),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    position.x -= gameRef.scrollSpeed * dt;

    // Shimmer effect
    _pulseTime += dt;
    final pulse = 0.6 + 0.4 * ((_pulseTime * 3) % 1.0);
    paint.color = Color.lerp(
      const Color(0xFF42A5F5),
      const Color(0xFF81D4FA),
      pulse,
    )!;

    if (position.x < -30) {
      removeFromParent();
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    gameRef.powerupSystem.activateShield();
    removeFromParent();
  }
}


