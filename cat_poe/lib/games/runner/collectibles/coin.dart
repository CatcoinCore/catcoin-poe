import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import '../systems/powerup_system.dart';

/// Collectible coin â€” each one is worth 1 catoshi.
/// When coin magnet is active, coins within range auto-fly toward the player.
class Coin extends CircleComponent with CollisionCallbacks {
  final RunnerGame gameRef;
  bool _collected = false;

  // Bobbing animation
  double _bobTime = 0;
  late double _baseY;
  static const double bobAmplitude = 4.0;
  static const double bobSpeed = 4.0;

  Coin({
    required this.gameRef,
    required Vector2 position,
  }) : super(
          radius: 10,
          position: position,
          paint: Paint()..color = const Color(0xFFFFD700), // Gold
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    _baseY = position.y;

    // Inner circle for coin detail
    add(
      CircleComponent(
        radius: 5,
        position: Vector2(10, 10),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFFA000),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;

    // Move left with the world scroll
    position.x -= gameRef.scrollSpeed * dt;

    // Bobbing animation
    _bobTime += dt;
    position.y = _baseY + bobAmplitude * (bobAmplitude * (0.5 + 0.5 * _sinApprox(_bobTime * bobSpeed)));

    // Magnet pull â€” attract toward player when magnet is active
    if (gameRef.powerupSystem.isMagnetActive) {
      final playerPos = gameRef.player.position + gameRef.player.size / 2;
      final coinCenter = position;
      final dist = playerPos.distanceTo(coinCenter);

      if (dist < PowerupSystem.magnetRadius && dist > 5) {
        final dir = (playerPos - coinCenter)..normalize();
        final pullSpeed = 300.0; // px/sec toward player
        position += dir * pullSpeed * dt;
        _baseY = position.y; // Update base to prevent bobbing from fighting pull
      }
    }

    // Remove if off-screen
    if (position.x < -20) {
      removeFromParent();
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    gameRef.economyManager.collectCoin();
    gameRef.powerupSystem.addTurboCharge();
    removeFromParent();
  }

  /// Simple sin approximation for bobbing
  double _sinApprox(double x) {
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    return x - (x * x * x) / 6.0 + (x * x * x * x * x) / 120.0;
  }
}


