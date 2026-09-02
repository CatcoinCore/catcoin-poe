import 'package:flame/components.dart';

import '../game/runner_game.dart';

/// Consolidated powerup state manager.
/// Manages turbo, coin magnet, and shield durations + effects.
class PowerupSystem extends Component {
  final RunnerGame game;

  // â”€â”€ Turbo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool isTurboActive = false;
  double _turboRemaining = 0;
  static const double turboDuration = 5.0;
  
  // Meter ranges from 0.0 to 1.0
  double turboMeter = 0.0;
  // How much a single coin fills the meter
  static const double turboChargePerCoin = 0.05;

  // â”€â”€ Coin Magnet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool isMagnetActive = false;
  double _magnetRemaining = 0;
  static const double magnetDuration = 5.0;
  static const double magnetRadius = 120.0;

  // â”€â”€ Shield â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool hasShield = false;

  PowerupSystem({required this.game});

  @override
  void update(double dt) {
    super.update(dt);

    // Turbo timer
    if (isTurboActive) {
      _turboRemaining -= dt;
      if (_turboRemaining <= 0) {
        isTurboActive = false;
        _turboRemaining = 0;
      }
    }

    // Magnet timer
    if (isMagnetActive) {
      _magnetRemaining -= dt;
      if (_magnetRemaining <= 0) {
        isMagnetActive = false;
        _magnetRemaining = 0;
      }
    }
  }

  void activateTurbo() {
    if (turboMeter < 1.0) return; // Must be fully charged
    isTurboActive = true;
    _turboRemaining = turboDuration;
    turboMeter = 0.0; // Reset meter when activated
    game.economyManager.addScore(25);
  }

  void addTurboCharge() {
    if (isTurboActive) return; // Don't charge while active
    
    turboMeter += turboChargePerCoin;
    if (turboMeter >= 1.0) {
      turboMeter = 1.0;
      // Removed automatic activation, now waits for user tap
    }
  }
  
  bool get canActivateTurbo => turboMeter >= 1.0 && !isTurboActive;

  void activateMagnet() {
    isMagnetActive = true;
    _magnetRemaining = magnetDuration;
    game.economyManager.addScore(15);
  }

  void activateShield() {
    hasShield = true;
    game.economyManager.addScore(10);
  }

  /// Consume the shield on enemy hit. Returns true if shield absorbed the hit.
  bool consumeShield() {
    if (hasShield) {
      hasShield = false;
      return true;
    }
    return false;
  }

  double get turboRemaining => _turboRemaining;
  double get magnetRemaining => _magnetRemaining;

  void reset() {
    isTurboActive = false;
    _turboRemaining = 0;
    isMagnetActive = false;
    _magnetRemaining = 0;
    hasShield = false;
    turboMeter = 0.0;
  }
}


