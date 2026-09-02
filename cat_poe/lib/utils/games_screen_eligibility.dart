import '../models/admin_config.dart';
import '../providers/game_provider.dart';

/// Whether a game row is rendered on [GamesScreen] for the given admin config.
/// Mirrors `if (config == null || config.is…Visible)` blocks in [GamesScreen].
bool isGameRowOnGamesScreenVisible(AdminConfig? config, String gameType) {
  if (config == null) return true;
  switch (gameType) {
    case 'RUNNER':
      return config.isRunnerGameVisible;
    case 'MINER':
      return config.isMinerGameVisible;
    case 'TICTACTOE':
      return config.isTictactoeGameVisible;
    case 'SUDOKU':
      return config.isSudokuGameVisible;
    case 'COLLAGE':
      return config.isCollageGameVisible;
    case 'ARROW':
      return config.isArrowGameVisible;
    case 'TWENTY48':
      return config.isTwenty48GameVisible;
    case 'TILE_SWAP':
      return config.isTileSwapGameVisible;
    default:
      return false;
  }
}

/// Same openability rules as [GamesScreen] `_canOpenGame`.
bool gameCanOpenOnGamesScreen(
  GameStatusItem? status,
  String gameType, {
  required bool hasLaunchAction,
}) {
  if (gameType == 'RUNNER') {
    return status?.canPlay ?? true;
  }
  if (gameType == 'MINER' ||
      gameType == 'ARROW' ||
      gameType == 'TWENTY48' ||
      gameType == 'TILE_SWAP') {
    if (!hasLaunchAction) return false;
    // New game types may be missing from older `/game/status` payloads (older
    // backend / not-yet-seeded `game_reward_config`); allow opening.
    if (status == null) return true;
    return status.canPlay;
  }
  if (!hasLaunchAction) return false;
  return status?.canPlay == true;
}

/// True if at least one game card section would be shown (used for empty state).
bool anyGameRowOnGamesScreenVisible(AdminConfig? config) {
  if (config == null) return true;
  return isGameRowOnGamesScreenVisible(config, 'RUNNER') ||
      isGameRowOnGamesScreenVisible(config, 'MINER') ||
      isGameRowOnGamesScreenVisible(config, 'TICTACTOE') ||
      isGameRowOnGamesScreenVisible(config, 'SUDOKU') ||
      isGameRowOnGamesScreenVisible(config, 'COLLAGE') ||
      isGameRowOnGamesScreenVisible(config, 'ARROW') ||
      isGameRowOnGamesScreenVisible(config, 'TWENTY48') ||
      isGameRowOnGamesScreenVisible(config, 'TILE_SWAP');
}

/// Playable games that appear on [GamesScreen]: visible in admin config and openable
/// per the same rules as the list cards. Keep game order and `hasLaunchAction`
/// flags aligned with [GamesScreen].
int visiblePlayableGamesCount({
  required AdminConfig? config,
  required Map<String, GameStatusItem> statusMap,
}) {
  var n = 0;

  void countIfPlayable(String gameType, bool hasLaunchAction) {
    if (!isGameRowOnGamesScreenVisible(config, gameType)) return;
    final status = statusMap[gameType];
    if (gameCanOpenOnGamesScreen(
      status,
      gameType,
      hasLaunchAction: hasLaunchAction,
    )) {
      n++;
    }
  }

  countIfPlayable('RUNNER', true);
  countIfPlayable('MINER', true);
  countIfPlayable('TICTACTOE', true);
  countIfPlayable('SUDOKU', true);
  countIfPlayable('COLLAGE', true);
  countIfPlayable('ARROW', true);
  countIfPlayable('TWENTY48', true);
  countIfPlayable('TILE_SWAP', true);
  return n;
}

/// Whether TicTacToe "Play again" should be enabled (server limits + local busy flags).
bool ticTacToePlayAgainEnabled(
  GameStatusItem? status, {
  required bool isSubmitting,
  required bool roundResolutionBusy,
}) {
  return (status == null || status.canPlay) &&
      !isSubmitting &&
      !roundResolutionBusy;
}
