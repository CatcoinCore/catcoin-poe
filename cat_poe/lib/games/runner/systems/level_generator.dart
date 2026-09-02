import 'dart:math';
import 'package:flame/components.dart';

import '../game/runner_game.dart';
import '../collectibles/coin.dart';
import '../enemies/enemy_base.dart';
import '../game/platform.dart';
import '../obstacles/obstacle.dart';
import '../collectibles/magnet_pickup.dart';
import '../collectibles/shield_pickup.dart';

/// Difficulty tier
enum DifficultyTier { easy, medium, hard, expert }

DifficultyTier tierForDistance(int distanceMeters) {
  if (distanceMeters < 500) return DifficultyTier.easy;
  if (distanceMeters < 1500) return DifficultyTier.medium;
  if (distanceMeters < 3000) return DifficultyTier.hard;
  return DifficultyTier.expert;
}

/// Procedural level generator with tiered difficulty.
/// Spawns coins, themed enemies, and powerups ahead of the camera.
class LevelGenerator extends Component {
  final RunnerGame game;
  final Random _rng = Random();

  double _nextSpawnX = 0.0;
  double _lastPlatformY = RunnerGame.worldHeight - 40;
  int _powerupCounter = 0;
  DifficultyTier _currentTier = DifficultyTier.easy;

  LevelGenerator({required this.game});

  // â”€â”€ Tier-specific parameters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  double get _minGap {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 100.0;
      case DifficultyTier.medium: return 120.0;
      case DifficultyTier.hard:   return 150.0;
      case DifficultyTier.expert: return 180.0;
    }
  }

  double get _maxGap {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 150.0;
      case DifficultyTier.medium: return 180.0;
      case DifficultyTier.hard:   return 220.0;
      case DifficultyTier.expert: return 260.0;
    }
  }

  double get _minSpeed {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 200.0;
      case DifficultyTier.medium: return 250.0;
      case DifficultyTier.hard:   return 350.0;
      case DifficultyTier.expert: return 450.0;
    }
  }

  double get _maxSpeed {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 250.0;
      case DifficultyTier.medium: return 350.0;
      case DifficultyTier.hard:   return 450.0;
      case DifficultyTier.expert: return 550.0;
    }
  }

  int get _powerupInterval {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 20;
      case DifficultyTier.medium: return 15;
      case DifficultyTier.hard:   return 12;
      case DifficultyTier.expert: return 10;
    }
  }

  double get _enemyChance {
    switch (_currentTier) {
      case DifficultyTier.easy:   return 0.25;
      case DifficultyTier.medium: return 0.40;
      case DifficultyTier.hard:   return 0.55;
      case DifficultyTier.expert: return 0.75;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    // Update tier
    _currentTier = tierForDistance(game.economyManager.distanceMeters);

    // Scale scroll speed within tier range based on distance within tier
    final dist = game.economyManager.distanceMeters;
    double tierProgress;
    switch (_currentTier) {
      case DifficultyTier.easy:
        tierProgress = dist / 500.0;
        break;
      case DifficultyTier.medium:
        tierProgress = (dist - 500) / 1000.0;
        break;
      case DifficultyTier.hard:
        tierProgress = (dist - 1500) / 1500.0;
        break;
      case DifficultyTier.expert:
        tierProgress = min(1.0, (dist - 3000) / 2000.0);
        break;
    }
    game.scrollSpeed = _minSpeed + (_maxSpeed - _minSpeed) * tierProgress.clamp(0, 1);

    if (game.powerupSystem.isTurboActive) {
      game.scrollSpeed *= 2.0;
    }

    // Spawn new entities
    while (_nextSpawnX < game.distanceTraveled + RunnerGame.worldWidth + 800) {
      _spawnPlatformSegment();
    }
  }

  void _spawnPlatformSegment() {
    _powerupCounter++;

    // Calculate platform size and Y position
    final isFirst = _nextSpawnX == 0.0;
    // Initial safe zone gives the user plenty of time before the first gap
    final platformWidth = isFirst ? 3200.0 : 400.0 + _rng.nextDouble() * 600.0;
    
    double platformY = _lastPlatformY;
    if (!isFirst) {
      // Vary platform height slightly
      platformY += (_rng.nextDouble() * 80) - 40;
      // Clamp to visible area (keep it relatively low to leave headroom for double jumps)
      platformY = platformY.clamp(RunnerGame.worldHeight - 150, RunnerGame.worldHeight - 40);
    }
    _lastPlatformY = platformY;

    final absoluteSpawnX = _nextSpawnX - game.distanceTraveled;

    // Spawn the platform
    game.world.add(GamePlatform(
      gameRef: game,
      position: Vector2(absoluteSpawnX, platformY),
      size: Vector2(platformWidth, RunnerGame.worldHeight - platformY + 200),
    ));

    // Spawn items on this platform
    final spawnCount = (platformWidth / 300).floor(); // Spawn items per 300px
    
    for (int s = 0; s < spawnCount; s++) {
      // If it's the very first platform, skip the first 600 pixels so the player has 3 seconds to breathe
      final startOffset = isFirst ? 600.0 : 150.0;
      final localX = absoluteSpawnX + startOffset + s * 300 + _rng.nextDouble() * 50;
      
      // Don't spawn things at the very edge of the chunk
      if (localX > absoluteSpawnX + platformWidth - 100) continue;

      final subRoll = _rng.nextDouble();
      
      if (subRoll < 0.20) {
        // Obstacle (Spikes or Crate)
        final type = _rng.nextBool() ? ObstacleType.spikes : ObstacleType.crate;
        final obsSizeY = type == ObstacleType.spikes ? 15.0 : 40.0;
        game.world.add(Obstacle(
          gameRef: game,
          type: type,
          position: Vector2(localX, platformY - obsSizeY),
        ));
      } else if (subRoll < 0.20 + _enemyChance) {
        // Enemy
        final enemyType = _pickEnemyType();
        final isFlying = enemyType == EnemyType.drone;
        final enemyY = isFlying
            ? platformY - 120 - _rng.nextDouble() * 60
            : platformY - (enemyType == EnemyType.angryDog ? 35 : 22);

        game.world.add(Enemy(
          gameRef: game,
          type: enemyType,
          position: Vector2(localX, enemyY),
        ));
      } else {
        // Coins
        final count = 2 + _rng.nextInt(3);
        final arcHeight = _rng.nextBool() ? 0.0 : 60.0;
        for (int i = 0; i < count; i++) {
          final coinPos = Vector2(
            localX + i * 35,
            platformY - 50 - arcHeight - (i < count ~/ 2 ? i * 15.0 : (count - 1 - i) * 15.0),
          );
          game.world.add(Coin(gameRef: game, position: coinPos));
        }
      }
    }

    // Powerup spawning
    if (_powerupCounter >= _powerupInterval) {
      _powerupCounter = 0;
      _spawnPowerup(absoluteSpawnX + platformWidth / 2, platformY);
    }

    // Advance spawn position with a gap
    final gap = isFirst ? 0.0 : _minGap + _rng.nextDouble() * (_maxGap - _minGap);
    _nextSpawnX += platformWidth + gap;
  }

  EnemyType _pickEnemyType() {
    switch (_currentTier) {
      case DifficultyTier.easy:
        // Only robot vacuums
        return EnemyType.robotVacuum;
      case DifficultyTier.medium:
        // Robot vacuums + drones
        return _rng.nextBool() ? EnemyType.robotVacuum : EnemyType.drone;
      case DifficultyTier.hard:
        // All three types
        final r = _rng.nextInt(3);
        if (r == 0) return EnemyType.robotVacuum;
        if (r == 1) return EnemyType.drone;
        return EnemyType.angryDog;
      case DifficultyTier.expert:
        // Heavily favor angry dogs and drones
        final r2 = _rng.nextDouble();
        if (r2 < 0.2) return EnemyType.robotVacuum;
        if (r2 < 0.5) return EnemyType.drone;
        return EnemyType.angryDog;
    }
  }

  void _spawnPowerup(double xPos, double platformY) {
    final pickupY = platformY - 80 - _rng.nextDouble() * 60;
    final pickupX = xPos;

    // Rotate between magnet, shield
    final type = _rng.nextInt(2);
    switch (type) {
      case 0:
        game.world.add(MagnetPickup(
          gameRef: game,
          position: Vector2(pickupX, pickupY),
        ));
        break;
      case 1:
        game.world.add(ShieldPickup(
          gameRef: game,
          position: Vector2(pickupX, pickupY),
        ));
        break;
    }
  }

  void reset() {
    _nextSpawnX = 0.0;
    _lastPlatformY = RunnerGame.worldHeight - 40;
    _powerupCounter = 0;
    _currentTier = DifficultyTier.easy;
  }
}


