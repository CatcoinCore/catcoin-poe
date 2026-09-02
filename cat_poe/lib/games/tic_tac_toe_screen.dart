import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../providers/game_provider.dart';
import '../providers/mining_provider.dart';
import '../utils/game_screen_capture_guard.dart';
import '../utils/game_session_gate.dart';
import '../utils/game_cooldown_format.dart';
import '../utils/game_reward_feedback.dart';
import '../utils/games_screen_eligibility.dart';
import '../services/ad_service.dart';
import '../services/game_sfx_service.dart';
import '../services/tictactoe_ad_counter.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with GameScreenCaptureGuard {
  late List<String> board;
  late bool isXTurn;
  bool _userStartsNext = true;
  String? winner;
  bool isGameOver = false;
  bool isSubmitting = false;

  bool _roundResolutionBusy = false;
  Timer? _cooldownUiTimer;

  @override
  void initState() {
    super.initState();
    _resetGame();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'TICTACTOE')) return;
      if (!mounted) return;
      await _startSession();
      if (!mounted) return;
      AdService().loadInterstitialAd(context);
    });
  }

  @override
  void dispose() {
    _cooldownUiTimer?.cancel();
    super.dispose();
  }

  void _maybeStartCooldownTicker() {
    _cooldownUiTimer?.cancel();
    if (!isGameOver) return;
    final st =
        Provider.of<GameProvider>(context, listen: false).statusMap['TICTACTOE'];
    if (st == null || st.canPlay) return;

    _cooldownUiTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final gp = Provider.of<GameProvider>(context, listen: false);
      final s = gp.statusMap['TICTACTOE'];
      if (s?.canPlay == true) {
        _cooldownUiTimer?.cancel();
        setState(() {});
        return;
      }
      final until = s?.cooldownUntil;
      if (until != null && !DateTime.now().isBefore(until)) {
        await gp.fetchStatus();
      }
      if (mounted) setState(() {});
    });
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      isXTurn = _userStartsNext;
      _userStartsNext = !_userStartsNext;
      winner = null;
      isGameOver = false;
    });

    if (!isXTurn) {
      Future.delayed(const Duration(milliseconds: 500), _makeCPUMove);
    }
  }

  Future<void> _startSession() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.startSession();
  }

  /// After any terminal position: sync limits, every-3-games ad gate, then reward if X won.
  Future<void> _resolveRoundAfterGameEnd({required bool playerWonReward}) async {
    if (_roundResolutionBusy) return;
    _roundResolutionBusy = true;
    try {
      final gp = Provider.of<GameProvider>(context, listen: false);
      await gp.fetchStatus();
      if (!context.mounted) return;

      final count = await TicTacToeAdCounterStore.incrementAndGet();
      if (!mounted) return;
      if (count >= 3) {
        await AdService()
            .showRewardGateAd(context, gameType: 'TICTACTOE');
        await TicTacToeAdCounterStore.reset();
      }
      if (!context.mounted) return;

      if (playerWonReward) {
        await _submitResult();
      }

      if (context.mounted) {
        setState(() {});
        _maybeStartCooldownTicker();
      }
    } finally {
      _roundResolutionBusy = false;
    }
  }

  void _scheduleRoundResolution({required bool playerWonReward}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_resolveRoundAfterGameEnd(playerWonReward: playerWonReward));
      }
    });
  }

  void _handleTap(int index) {
    if (board[index] != '' || isGameOver || !isXTurn) return;

    final sfx = GameSfxService.instance;
    var xWon = false;
    var isDraw = false;

    setState(() {
      board[index] = 'X';
      if (_checkWinner('X')) {
        winner = 'X';
        isGameOver = true;
        xWon = true;
        _scheduleRoundResolution(playerWonReward: true);
      } else if (board.every((cell) => cell != '')) {
        isGameOver = true;
        isDraw = true;
        _scheduleRoundResolution(playerWonReward: false);
      } else {
        isXTurn = false;
        Future.delayed(const Duration(milliseconds: 500), _makeCPUMove);
      }
    });

    if (xWon) {
      sfx.play(GameSfx.win, volume: 0.74);
    } else if (isDraw) {
      sfx.play(GameSfx.softTap, volume: 0.42);
    } else {
      sfx.play(GameSfx.tap, volume: 0.62);
    }
  }

  int _findBestMove(List<int> availableMoves) {
    if (Random().nextDouble() < 0.4) {
      return availableMoves[Random().nextInt(availableMoves.length)];
    }

    for (int i in availableMoves) {
      board[i] = 'O';
      if (_checkWinner('O')) {
        board[i] = '';
        return i;
      }
      board[i] = '';
    }

    for (int i in availableMoves) {
      board[i] = 'X';
      if (_checkWinner('X')) {
        board[i] = '';
        return i;
      }
      board[i] = '';
    }

    if (board[4] == '') return 4;

    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int corner in corners) {
      if (board[corner] == '') return corner;
    }

    return -1;
  }

  void _makeCPUMove() {
    if (isGameOver) return;

    List<int> availableMoves = [];
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') availableMoves.add(i);
    }

    if (availableMoves.isNotEmpty) {
      int move = _findBestMove(availableMoves);
      if (move == -1) {
        move = availableMoves[Random().nextInt(availableMoves.length)];
      }

      final sfx = GameSfxService.instance;
      var oWon = false;
      var isDraw = false;

      setState(() {
        board[move] = 'O';
        if (_checkWinner('O')) {
          winner = 'O';
          isGameOver = true;
          oWon = true;
          _scheduleRoundResolution(playerWonReward: false);
        } else if (board.every((cell) => cell != '')) {
          isGameOver = true;
          isDraw = true;
          _scheduleRoundResolution(playerWonReward: false);
        } else {
          isXTurn = true;
        }
      });

      if (oWon) {
        sfx.play(GameSfx.lose, volume: 0.55);
      } else if (isDraw) {
        sfx.play(GameSfx.softTap, volume: 0.42);
      } else {
        sfx.play(GameSfx.softTap, volume: 0.52);
      }
    }
  }

  bool _checkWinner(String player) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var line in lines) {
      if (board[line[0]] == player &&
          board[line[1]] == player &&
          board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  void _showTictactoeRewardDialog(int catoshi, GameBoostAward? boost) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
        title: Text(
          l10n.gameYouWin,
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.gameTictactoeSuccess(catoshi.toString()),
                textAlign: TextAlign.center,
              ),
              if (boost != null) ...gameBoostBonusSection(ctx, l10n, boost),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResult() async {
    if (winner != 'X') return;

    final messenger = ScaffoldMessenger.of(context);
    final mining = Provider.of<MiningProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    setState(() {
      isSubmitting = true;
    });

    final success = await gameProvider.submitScore(
      score: 1,
      coinsCollected: 10,
      gameType: "TICTACTOE",
    );

    if (!context.mounted) return;

    if (success) {
      mining.fetchStats();
      await gameProvider.fetchStatus();
      if (!context.mounted) return;
      // Dialog after interstitial / async work so it is not lost like a SnackBar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final reward = gameProvider.lastReward ?? 10;
        _showTictactoeRewardDialog(
          reward,
          gameProvider.lastGameBoostAward,
        );
      });
    } else if (gameProvider.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(gameProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!context.mounted) return;
    setState(() {
      isSubmitting = false;
    });
    _maybeStartCooldownTicker();
  }

  Future<void> _onPlayAgain() async {
    if (isSubmitting || _roundResolutionBusy) return;
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.fetchStatus();
    if (!mounted) return;
    final st = gp.statusMap['TICTACTOE'];
    if (st == null || !st.canPlay) {
      setState(() {});
      _maybeStartCooldownTicker();
      return;
    }
    _cooldownUiTimer?.cancel();
    _resetGame();
    await _startSession();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.gamesTictactoeTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)
                ],
              ),
              child: Text(
                l.gameWinReward('10'),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              winner == 'X'
                  ? l.gameYouWin
                  : (winner == 'O'
                      ? l.gameCpuWins
                      : (isGameOver ? l.gameDraw : l.gameYourTurnX)),
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color ??
                    Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 9,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _handleTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: winner == 'X' && board[index] == 'X'
                                ? Colors.green
                                : (winner == 'O' && board[index] == 'O'
                                    ? Colors.red
                                    : Theme.of(context).dividerColor),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            board[index],
                            style: TextStyle(
                              color: board[index] == 'X'
                                  ? Colors.orange
                                  : Colors.blue,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (isGameOver)
              Consumer<GameProvider>(
                builder: (context, gp, _) {
                  final st = gp.statusMap['TICTACTOE'];
                  final canPlayAgain = ticTacToePlayAgainEnabled(
                    st,
                    isSubmitting: isSubmitting,
                    roundResolutionBusy: _roundResolutionBusy,
                  );
                  final remaining =
                      formatGameCooldownRemaining(st?.cooldownUntil);
                  final showCooldownMsg = st != null && !st.canPlay;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (showCooldownMsg) ...[
                          Text(
                            remaining != null
                                ? l.gameCooldownComeBack(remaining)
                                : l.gameCooldownLimitReached,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: canPlayAgain ? _onPlayAgain : null,
                          icon: const Icon(Icons.replay),
                          label: Text(l.gamePlayAgain),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (isSubmitting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}
