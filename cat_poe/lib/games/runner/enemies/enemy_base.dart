import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';

/// Themed enemy types from the GDD
enum EnemyType { robotVacuum, drone, angryDog }

/// Enemy obstacle â€” kills the player on contact (unless turbo/shield is active).
class Enemy extends RectangleComponent with CollisionCallbacks {
  final RunnerGame gameRef;
  final EnemyType type;

  Enemy({
    required this.gameRef,
    required this.type,
    required Vector2 position,
  }) : super(
          size: _sizeFor(type),
          position: position,
          paint: Paint()..color = _colorFor(type),
        );

  static Vector2 _sizeFor(EnemyType type) {
    switch (type) {
      case EnemyType.robotVacuum:
        return Vector2(35, 22);
      case EnemyType.drone:
        return Vector2(32, 20);
      case EnemyType.angryDog:
        return Vector2(45, 35);
    }
  }

  static Color _colorFor(EnemyType type) {
    switch (type) {
      case EnemyType.robotVacuum:
        return const Color(0xFF607D8B); // Blue grey
      case EnemyType.drone:
        return const Color(0xFF37474F); // Dark grey
      case EnemyType.angryDog:
        return const Color(0xFF8D6E63); // Brown
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    switch (type) {
      case EnemyType.robotVacuum:
        _buildRobotVacuum();
        break;
      case EnemyType.drone:
        _buildDrone();
        break;
      case EnemyType.angryDog:
        _buildAngryDog();
        break;
    }

    // Floating text label identifying the enemy type
    add(TextComponent(
      text: type.name.toUpperCase(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54, // Better contrast against sky
        ),
      ),
      position: Vector2(size.x / 2, -15),
      anchor: Anchor.center,
    ));
  }

  void _buildRobotVacuum() {
    // Rounded body with red sensor light
    add(CircleComponent(
      radius: 4,
      position: Vector2(size.x / 2, 4),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFE53935), // Red sensor
    ));
    // Wheels
    add(CircleComponent(
      radius: 5,
      position: Vector2(6, size.y),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF263238),
    ));
    add(CircleComponent(
      radius: 5,
      position: Vector2(size.x - 6, size.y),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF263238),
    ));
    // Bumper bar
    add(RectangleComponent(
      size: Vector2(size.x - 4, 3),
      position: Vector2(2, 0),
      paint: Paint()..color = const Color(0xFF455A64),
    ));
  }

  void _buildDrone() {
    // 4 propeller arms
    for (int i = 0; i < 4; i++) {
      final x = i < 2 ? (i * 20.0) : ((i - 2) * 20.0);
      final y = i < 2 ? -4.0 : -4.0;
      add(RectangleComponent(
        size: Vector2(8, 3),
        position: Vector2(x + 2, y),
        paint: Paint()..color = const Color(0xFF78909C),
      ));
    }
    // Camera lens
    add(CircleComponent(
      radius: 3,
      position: Vector2(size.x / 2, size.y - 2),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFE53935),
    ));
    // LED indicators
    add(CircleComponent(
      radius: 1.5,
      position: Vector2(5, 6),
      paint: Paint()..color = const Color(0xFF4CAF50), // Green LED
    ));
    add(CircleComponent(
      radius: 1.5,
      position: Vector2(size.x - 7, 6),
      paint: Paint()..color = const Color(0xFF4CAF50),
    ));
  }

  void _buildAngryDog() {
    // Ears
    add(RectangleComponent(
      size: Vector2(8, 10),
      position: Vector2(4, -8),
      paint: Paint()..color = const Color(0xFF6D4C41),
    ));
    add(RectangleComponent(
      size: Vector2(8, 10),
      position: Vector2(size.x - 12, -8),
      paint: Paint()..color = const Color(0xFF6D4C41),
    ));
    // Angry eyes
    add(RectangleComponent(
      size: Vector2(6, 4),
      position: Vector2(10, 6),
      paint: Paint()..color = const Color(0xFFE53935),
    ));
    add(RectangleComponent(
      size: Vector2(6, 4),
      position: Vector2(size.x - 16, 6),
      paint: Paint()..color = const Color(0xFFE53935),
    ));
    // Snout
    add(RectangleComponent(
      size: Vector2(10, 6),
      position: Vector2(size.x - 10, 12),
      paint: Paint()..color = const Color(0xFFA1887F),
    ));
    // Tail
    add(RectangleComponent(
      size: Vector2(4, 14),
      position: Vector2(-4, 4),
      paint: Paint()..color = const Color(0xFF6D4C41),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Scroll left
    position.x -= gameRef.scrollSpeed * dt;

    // Remove if off-screen
    if (position.x < -60) {
      removeFromParent();
    }
  }
}


