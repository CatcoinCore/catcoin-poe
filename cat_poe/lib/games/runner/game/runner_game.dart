import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player/cat_player.dart';
import 'parallax_background.dart';
import '../systems/level_generator.dart';
import '../systems/economy_manager.dart';
import '../systems/powerup_system.dart';
import '../systems/collision_system.dart';
import '../systems/asset_pack_service.dart';

/// Game states for the auto-runner
enum GameState { playing, paused, gameOver }

/// Main CatCoin Runner game — a side-scrolling auto-runner built with Flame.
class RunnerGame extends FlameGame with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  final AssetPackService assetService;

  RunnerGame({required this.assetService});

  // —— Core systems ——————————————————————————————
  late PlayerCat player;
  late LevelGenerator levelGenerator;
  late EconomyManager economyManager;
  late PowerupSystem powerupSystem;
  late GameBackground background;
  late CollisionSystem collisionSystem;

  // â”€â”€ Game state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  GameState state = GameState.playing;
  double scrollSpeed = 200.0; // pixels per second
  static const double baseScrollSpeed = 200.0;
  double distanceTraveled = 0.0;

  // â”€â”€ Callbacks to overlays â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  VoidCallback? onGameOver;

  // â”€â”€ Viewport â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double worldWidth = 800.0;
  static const double worldHeight = 450.0; // 16:9

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Use a fixed-resolution camera so the game looks the same on all devices
    camera.viewfinder.visibleGameSize = Vector2(worldWidth, worldHeight);
    camera.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Systems
    economyManager = EconomyManager();
    powerupSystem = PowerupSystem(game: this);
    levelGenerator = LevelGenerator(game: this);
    collisionSystem = CollisionSystem(game: this);

    // Background
    background = GameBackground();
    world.add(background);

    // Player â€” positioned at 20% horizontal, spawning midway in the air so it lands on the first platform
    player = PlayerCat(gameRef: this);
    player.position = Vector2(worldWidth * 0.2, worldHeight - 150 - player.size.y);
    world.add(player);

    // Start systems
    world.add(levelGenerator);
    world.add(powerupSystem);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state != GameState.playing) return;

    // Advance distance
    distanceTraveled += scrollSpeed * dt;
    economyManager.distanceMeters = (distanceTraveled / 50).floor(); // 50px = 1m
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (state == GameState.playing) {
      player.jump();
    }
  }

  // Track jump key state to only trigger on leading edge of press
  bool _jumpKeyDown = false;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isJumpKey = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);

    if (event is KeyDownEvent && isJumpKey && !_jumpKeyDown) {
      // Leading edge: first press
      _jumpKeyDown = true;
      if (state == GameState.playing) {
        player.jump();
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      // Clear the flag when any key is released
      final wasJumpKey = event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW;
      if (wasJumpKey) _jumpKeyDown = false;
    }

    return KeyEventResult.ignored;
  }

  /// Called when the player dies (hit an enemy)
  void triggerGameOver() {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    pauseEngine();
    overlays.add('GameOver');
    onGameOver?.call();
  }

  /// Restart the game
  void restart() {
    // Remove all spawned entities
    world.children
        .whereType<Component>()
        .where((c) => c != player && c != background && c != levelGenerator && c != powerupSystem)
        .toList()
        .forEach((c) => c.removeFromParent());

    // Reset state
    state = GameState.playing;
    scrollSpeed = baseScrollSpeed;
    distanceTraveled = 0.0;
    economyManager.reset();
    powerupSystem.reset();
    levelGenerator.reset();

    // Reset player
    player.resetState();
    player.position = Vector2(worldWidth * 0.2, worldHeight - 150 - player.size.y);

    // Remove overlays
    overlays.remove('GameOver');
    overlays.remove('Pause');

    resumeEngine();
  }

  void pauseGame() {
    if (state != GameState.playing) return;
    state = GameState.paused;
    pauseEngine();
    overlays.add('Pause');
  }

  void resumeGame() {
    if (state != GameState.paused) return;
    state = GameState.playing;
    overlays.remove('Pause');
    resumeEngine();
  }
}


