import 'package:flame/components.dart';

import '../game/runner_game.dart';
import '../collectibles/coin.dart';
import '../enemies/enemy_base.dart';
import '../collectibles/magnet_pickup.dart';
import '../collectibles/shield_pickup.dart';
import '../game/platform.dart';
import '../obstacles/obstacle.dart';
import '../player/cat_state_machine.dart';

/// Centralized collision handler as requested by the blueprint.
class CollisionSystem {
  final RunnerGame game;

  CollisionSystem({required this.game});

  /// Handles all player collisions
  void handlePlayerCollision(PositionComponent other) {
    if (other is GamePlatform) {
      final playerBottom = game.player.position.y + game.player.size.y;
      final platformTop = other.position.y;
      final playerRight = game.player.position.x + game.player.size.x;
      final playerLeft = game.player.position.x;
      final platformLeft = other.position.x;

      // Detect if we hit the left wall of a raised platform
      // (Player is moving right, their right edge crosses the platform's left edge, 
      // but their feet are significantly below the platform's surface)
      if (playerRight > platformLeft && playerLeft < platformLeft) {
        if (playerBottom > platformTop + 15) { // 15px tolerance so we don't die on tiny bumps
          game.player.die();
          return;
        }
      }

      // Land on platform if falling
      if (game.player.velocityY >= 0) {
        // Snap to top if hitting the top surface
        if (playerBottom - game.player.velocityY * 0.05 <= platformTop + 25) {
          game.player.currentPlatform = other;
          game.player.position.y = platformTop - game.player.size.y;
          game.player.velocityY = 0;
          game.player.isOnGround = true;
          game.player.jumpsRemaining = 2;

          if (!game.powerupSystem.isTurboActive && game.player.stateMachine.currentState != CatState.run) {
            game.player.forceRunState();
          }
        }
      }
    } else if (other is Obstacle) {
      if (other.type == ObstacleType.crate) {
        final playerBottom = game.player.position.y + game.player.size.y;
        final obsTop = other.position.y;
        final playerRight = game.player.position.x + game.player.size.x;
        final playerLeft = game.player.position.x;
        final obsLeft = other.position.x;

        // Check if hitting from front (side collision)
        if (playerRight > obsLeft && playerLeft < obsLeft) {
          if (playerBottom > obsTop + 15) { 
            // This is a direct hazard impact, let it pass down to hazard logic below
          }
        } else if (game.player.velocityY >= 0 && playerBottom - game.player.velocityY * 0.05 <= obsTop + 15) {
          // Player is above/falling onto the crate, so it acts like a platform
          game.player.currentPlatform = other;
          game.player.position.y = obsTop - game.player.size.y;
          game.player.velocityY = 0;
          game.player.isOnGround = true;
          game.player.jumpsRemaining = 2;

          if (!game.powerupSystem.isTurboActive && game.player.stateMachine.currentState != CatState.run) {
            game.player.forceRunState();
          }
          return;
        }
      }

      // If we didn't land on it (or it's spikes), it's a hazard hit
      if (game.powerupSystem.isTurboActive) {
        other.removeFromParent();
        game.economyManager.addScore(10);
      } else if (game.powerupSystem.consumeShield()) {
        other.removeFromParent();
      } else {
        game.player.die();
      }
    } else if (other is Coin) {
      other.collect();
    } else if (other is Enemy) {
      if (game.powerupSystem.isTurboActive) {
        // Invincible during turbo â€” push aside, no destruction negativity
        other.removeFromParent();
        game.economyManager.addScore(50);
      } else if (game.powerupSystem.consumeShield()) {
        // Shield absorbed the hit â€” push aside
        other.removeFromParent();
        game.economyManager.addScore(30);
      } else {
        game.player.die();
      }
    } else if (other is MagnetPickup) {
      other.collect();
    } else if (other is ShieldPickup) {
      other.collect();
    }
  }
}

