import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/runner_game.dart';

enum ObstacleType { spikes, crate }

/// Non-enemy hazard. Spikes kill the player, crates block movement.
class Obstacle extends RectangleComponent with CollisionCallbacks {
  final RunnerGame gameRef;
  final ObstacleType type;

  Obstacle({
    required this.gameRef,
    required this.type,
    required Vector2 position,
  }) : super(
          position: position,
          size: type == ObstacleType.spikes ? Vector2(30, 15) : Vector2(40, 40),
          paint: Paint()..color = type == ObstacleType.spikes ? Colors.grey.shade400 : Colors.brown.shade800,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    if (type == ObstacleType.spikes) {
      // Draw spike points
      add(PolygonComponent.relative(
        [
          Vector2(-1, 1),
          Vector2(0, -1),
          Vector2(1, 1),
        ],
        parentSize: Vector2(10, 15),
        position: Vector2(0, 0),
        paint: Paint()..color = Colors.grey.shade300,
      ));
      add(PolygonComponent.relative(
        [
          Vector2(-1, 1),
          Vector2(0, -1),
          Vector2(1, 1),
        ],
        parentSize: Vector2(10, 15),
        position: Vector2(10, 0),
        paint: Paint()..color = Colors.grey.shade300,
      ));
      add(PolygonComponent.relative(
        [
          Vector2(-1, 1),
          Vector2(0, -1),
          Vector2(1, 1),
        ],
        parentSize: Vector2(10, 15),
        position: Vector2(20, 0),
        paint: Paint()..color = Colors.grey.shade300,
      ));
    } else {
      // Crate details
      add(RectangleComponent(
        size: Vector2(30, 30),
        position: Vector2(5, 5),
        paint: Paint()..color = Colors.brown.shade600,
      ));
    }

    // Floating text label identifying the obstacle type
    add(TextComponent(
      text: type.name.toUpperCase(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      ),
      position: Vector2(size.x / 2, -12),
      anchor: Anchor.center,
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

