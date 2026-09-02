/// The states defined by the CatCoin Runner Blueprint.
enum CatState {
  idle,
  run,
  jump,
  doubleJump,
  fall,
  land,
  turbo,
  damage,
  victory,
}

/// A simple state machine to manage the player's current animation state
/// and valid transitions between them.
class CatStateMachine {
  CatState _currentState = CatState.run;

  CatState get currentState => _currentState;

  /// Attempts to transition to a new state.
  /// In a full implementation, you'd add rules here preventing e.g. jumping while dead.
  bool transitionTo(CatState nextState) {
    // If dead (damage) or victory, we usually lock state
    if (_currentState == CatState.damage && nextState != CatState.idle && nextState != CatState.run) {
      return false; // Already dead, can't jump etc.
    }

    _currentState = nextState;
    return true;
  }

  void reset() {
    _currentState = CatState.run;
  }
}

