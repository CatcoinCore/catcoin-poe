import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';

import 'cat_state_machine.dart';
import 'cat_animations.dart';

class PlayerCat extends PositionComponent with CollisionCallbacks {
  final RunnerGame gameRef;

  final CatStateMachine stateMachine = CatStateMachine();

  // Physics
  double velocityY = 0;
  static const double gravity = 1000.0; // Increased to bring cat down faster
  static const double jumpForce = -400.0; // Lowered jump height (was -450)
  static const double maxFallSpeed = 700.0;
  int jumpsRemaining = 2;
  bool isOnGround = true;
  PositionComponent? currentPlatform;

  // Visual
  static const double playerWidth = 40.0;
  static const double playerHeight = 50.0;

  late SpriteAnimationGroupComponent<CatState> animComponent;

  // Shield visual indicator
  CircleComponent? _shieldRing;

  PlayerCat({required this.gameRef})
      : super(
          size: Vector2(playerWidth, playerHeight),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    
    // Load and add sprite animations
    final anims = await CatAnimations.loadAnimations(gameRef, gameRef.assetService);
    animComponent = SpriteAnimationGroupComponent<CatState>(
      animations: anims,
      current: CatState.run,
      size: Vector2(128, 128), // 256x256 scaled down to look crisp
      position: Vector2(playerWidth / 2, playerHeight + 30), // Bottom centered, shifted further down so feet align with bounds
      anchor: Anchor.bottomCenter,
    );
    add(animComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.state != GameState.playing) return;
    if (stateMachine.currentState == CatState.damage) return;
    
    // Turbo check override
    if (gameRef.powerupSystem.isTurboActive && isOnGround) {
      if (stateMachine.currentState != CatState.turbo) {
        _setState(CatState.turbo);
      }
    }

    // Apply gravity
    velocityY += gravity * dt;
    velocityY = velocityY.clamp(-double.infinity, maxFallSpeed);
    position.y += velocityY * dt;

    // Platform snapping and fall-off detection
    if (currentPlatform != null) {
      if (position.x + size.x < currentPlatform!.position.x ||
          position.x > currentPlatform!.position.x + currentPlatform!.size.x) {
        // Walked off the edge
        currentPlatform = null;
        isOnGround = false;
        if (stateMachine.currentState != CatState.fall) {
          _setState(CatState.fall);
        }
      } else {
        // Keep snapped to platform top
        position.y = currentPlatform!.position.y - size.y;
        velocityY = 0;
        isOnGround = true;
      }
    } else {
      isOnGround = false;
      if (velocityY > 0 && stateMachine.currentState != CatState.fall) {
        _setState(CatState.fall);
      }
    }

    // Kill plane (fell into gap)
    if (position.y > RunnerGame.worldHeight + 100) {
      die();
    }

    // Update shield visual
    _updateShieldVisual();
  }

  void _updateShieldVisual() {
    if (gameRef.powerupSystem.hasShield && _shieldRing == null) {
      _shieldRing = CircleComponent(
        radius: 32,
        position: Vector2(playerWidth / 2, playerHeight / 2),
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xFF42A5F5).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      add(_shieldRing!);
    } else if (!gameRef.powerupSystem.hasShield && _shieldRing != null) {
      _shieldRing!.removeFromParent();
      _shieldRing = null;
    }
  }

  void jump() {
    if (stateMachine.currentState == CatState.damage) return;

    if (jumpsRemaining > 0) {
      velocityY = jumpForce;
      jumpsRemaining--;
      isOnGround = false;
      currentPlatform = null;

      if (jumpsRemaining == 1) {
        _setState(CatState.jump);
      } else {
        _setState(CatState.doubleJump);
      }
    }
  }

  void die() {
    if (stateMachine.currentState == CatState.damage) return;
    _setState(CatState.damage);
    gameRef.triggerGameOver();
  }

  void resetState() {
    stateMachine.reset();
    _setState(CatState.run);
    velocityY = 0;
    isOnGround = true;
    currentPlatform = null;
    jumpsRemaining = 2;
    if (_shieldRing != null) {
      _shieldRing!.removeFromParent();
      _shieldRing = null;
    }
  }

  void forceRunState() {
    _setState(CatState.run);
  }

  void _setState(CatState newState) {
    if (stateMachine.transitionTo(newState)) {
      animComponent.current = newState;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    gameRef.collisionSystem.handlePlayerCollision(other);
  }
}


