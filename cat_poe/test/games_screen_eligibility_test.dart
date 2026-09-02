import 'package:flutter_test/flutter_test.dart';

import 'package:cat_poe/models/admin_config.dart';
import 'package:cat_poe/providers/game_provider.dart';
import 'package:cat_poe/utils/games_screen_eligibility.dart';

AdminConfig _baseConfig() => AdminConfig.fromJson({});

GameStatusItem _status(
  String type, {
  required bool canPlay,
  int playCount = 0,
  int? maxGames,
}) {
  return GameStatusItem(
    gameType: type,
    playCount: playCount,
    maxGames: maxGames,
    canPlay: canPlay,
  );
}

void main() {
  group('visiblePlayableGamesCount', () {
    test('matches playable visible games; excludes hidden despite canPlay', () {
      final config = _baseConfig().copyWith(
        isSudokuGameVisible: false,
      );
      final statusMap = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
        'TICTACTOE': _status('TICTACTOE', canPlay: true),
        'SUDOKU': _status('SUDOKU', canPlay: true),
        'COLLAGE': _status('COLLAGE', canPlay: true),
        'ARROW': _status('ARROW', canPlay: true),
        'TWENTY48': _status('TWENTY48', canPlay: true),
        'TILE_SWAP': _status('TILE_SWAP', canPlay: true),
      };
      expect(
        visiblePlayableGamesCount(config: config, statusMap: statusMap),
        // RUNNER + TICTACTOE + COLLAGE + ARROW + TWENTY48 + TILE_SWAP = 6
        // (SUDOKU hidden; MINER status missing → openable but config visible
        //  brings it in via the missing-status branch → 7 total.)
        7,
      );
    });

    test('excludes MINER when server cooldown blocks plays', () {
      final config = _baseConfig();
      final statusMap = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
        'MINER': _status('MINER', canPlay: false),
        'TICTACTOE': _status('TICTACTOE', canPlay: true),
        'SUDOKU': _status('SUDOKU', canPlay: true),
        'ARROW': _status('ARROW', canPlay: false),
        'TWENTY48': _status('TWENTY48', canPlay: false),
        'TILE_SWAP': _status('TILE_SWAP', canPlay: false),
      };
      expect(
        visiblePlayableGamesCount(config: config, statusMap: statusMap),
        3,
      );
    });

    test('returns 0 when no games are playable (visible but locked)', () {
      final config = _baseConfig();
      final statusMap = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: false),
        'MINER': _status('MINER', canPlay: false),
        'TICTACTOE': _status('TICTACTOE', canPlay: false),
        'SUDOKU': _status('SUDOKU', canPlay: false),
        'COLLAGE': _status('COLLAGE', canPlay: false),
        'ARROW': _status('ARROW', canPlay: false),
        'TWENTY48': _status('TWENTY48', canPlay: false),
        'TILE_SWAP': _status('TILE_SWAP', canPlay: false),
      };
      expect(
        visiblePlayableGamesCount(config: config, statusMap: statusMap),
        0,
      );
    });

    test('updates when statusMap eligibility changes (same config)', () {
      final config = _baseConfig().copyWith(
        isMinerGameVisible: false,
        isCollageGameVisible: false,
        isArrowGameVisible: false,
        isTwenty48GameVisible: false,
        isTileSwapGameVisible: false,
      );
      final before = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
        'TICTACTOE': _status('TICTACTOE', canPlay: false),
      };
      final after = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
        'TICTACTOE': _status('TICTACTOE', canPlay: true),
      };
      expect(
        visiblePlayableGamesCount(config: config, statusMap: before),
        1,
      );
      expect(
        visiblePlayableGamesCount(config: config, statusMap: after),
        2,
      );
    });

    test('config null treats all rows visible; still applies canPlay rules',
        () {
      final statusMap = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
        'TICTACTOE': _status('TICTACTOE', canPlay: true),
        'SUDOKU': _status('SUDOKU', canPlay: true),
        'COLLAGE': _status('COLLAGE', canPlay: true),
        'ARROW': _status('ARROW', canPlay: true),
        'TWENTY48': _status('TWENTY48', canPlay: true),
        'TILE_SWAP': _status('TILE_SWAP', canPlay: true),
      };
      expect(
        visiblePlayableGamesCount(config: null, statusMap: statusMap),
        // 8 = all 7 above (each canPlay:true) + MINER (status missing →
        // openable per the MINER/ARROW/TWENTY48/TILE_SWAP missing-status branch).
        8,
      );
    });

    test('ARROW + TWENTY48 + TILE_SWAP are counted when status is missing (older backend)',
        () {
      final config = _baseConfig();
      final statusMap = <String, GameStatusItem>{
        'RUNNER': _status('RUNNER', canPlay: true),
      };
      expect(
        visiblePlayableGamesCount(config: config, statusMap: statusMap),
        // RUNNER (canPlay:true) + MINER + ARROW + TWENTY48 + TILE_SWAP
        // (status null → openable for these four)
        5,
      );
    });
  });

  group('ticTacToePlayAgainEnabled', () {
    test('disabled when server says cannot play', () {
      final st = _status('TICTACTOE', canPlay: false);
      expect(
        ticTacToePlayAgainEnabled(
          st,
          isSubmitting: false,
          roundResolutionBusy: false,
        ),
        false,
      );
    });

    test('disabled while submitting or resolving round', () {
      final st = _status('TICTACTOE', canPlay: true);
      expect(
        ticTacToePlayAgainEnabled(
          st,
          isSubmitting: true,
          roundResolutionBusy: false,
        ),
        false,
      );
      expect(
        ticTacToePlayAgainEnabled(
          st,
          isSubmitting: false,
          roundResolutionBusy: true,
        ),
        false,
      );
    });

    test('enabled when status unknown or canPlay', () {
      expect(
        ticTacToePlayAgainEnabled(
          null,
          isSubmitting: false,
          roundResolutionBusy: false,
        ),
        true,
      );
      expect(
        ticTacToePlayAgainEnabled(
          _status('TICTACTOE', canPlay: true),
          isSubmitting: false,
          roundResolutionBusy: false,
        ),
        true,
      );
    });
  });

  group('anyGameRowOnGamesScreenVisible', () {
    test('false when every game hidden', () {
      final config = _baseConfig().copyWith(
        isRunnerGameVisible: false,
        isMinerGameVisible: false,
        isTictactoeGameVisible: false,
        isSudokuGameVisible: false,
        isCollageGameVisible: false,
        isArrowGameVisible: false,
        isTwenty48GameVisible: false,
        isTileSwapGameVisible: false,
      );
      expect(anyGameRowOnGamesScreenVisible(config), false);
    });

    test('true when only ARROW + TWENTY48 + Tile Swap are visible', () {
      final config = _baseConfig().copyWith(
        isRunnerGameVisible: false,
        isMinerGameVisible: false,
        isTictactoeGameVisible: false,
        isSudokuGameVisible: false,
        isCollageGameVisible: false,
      );
      expect(anyGameRowOnGamesScreenVisible(config), true);
    });
  });

  group('isGameRowOnGamesScreenVisible', () {
    test('respects ARROW / TWENTY48 admin toggles', () {
      final config = _baseConfig().copyWith(
        isArrowGameVisible: false,
      );
      expect(isGameRowOnGamesScreenVisible(config, 'ARROW'), false);
      expect(isGameRowOnGamesScreenVisible(config, 'TWENTY48'), true);
      expect(isGameRowOnGamesScreenVisible(config, 'TILE_SWAP'), true);
    });

    test('respects Tile Swap admin toggle', () {
      final config = _baseConfig().copyWith(
        isTileSwapGameVisible: false,
      );
      expect(isGameRowOnGamesScreenVisible(config, 'TILE_SWAP'), false);
    });
  });
}
