import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/runner_game.dart';

/// A platform that the player can run and jump on.
class GamePlatform extends RectangleComponent with CollisionCallbacks {
  final RunnerGame gameRef;

  GamePlatform({
    required this.gameRef,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = const Color(0xFF6D4C41), // Brown dirt default
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    
    // Top grass layer
    add(RectangleComponent(
      size: Vector2(size.x, 10),
      paint: Paint()..color = const Color(0xFF66BB6A), // Green grass
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.state != GameState.playing) return;

    position.x -= gameRef.scrollSpeed * dt;

    if (position.x + size.x < -100) {
      removeFromParent();
    }
  }
}

