import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:cat_poe/l10n/app_localizations.dart';

import '../../../utils/game_screen_capture_guard.dart';
import '../../../utils/game_reward_feedback.dart';
import '../game/runner_game.dart';
import '../systems/asset_pack_service.dart';
import 'hud.dart';
import 'game_over_screen.dart';
import 'pause_menu.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/mining_provider.dart';
import '../../../services/ad_service.dart';

/// Screen that hosts the Flame GameWidget.
/// Forces landscape on enter, restores portrait on exit.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, GameScreenCaptureGuard {
  late RunnerGame _game;
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final assetService = Provider.of<AssetPackService>(context, listen: false);
    _game = RunnerGame(assetService: assetService);

    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start backend session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
      AdService().loadInterstitialAd(context);
    });
  }

  // ── Lifecycle: pause the Flame engine when the app loses focus.
  // This prevents the game from receiving stale keyboard events on resume
  // which would trigger the Flutter HardwareKeyboard assertion:
  //   '!_pressedKeys.containsKey(event.physicalKey)'
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Pause gameplay when app goes to background to avoid missed key-up
      // events causing assertion failures when focus is restored.
      if (_game.state == GameState.playing) {
        _game.pauseEngine();
        _appWasPaused = true;
      }
    } else if (state == AppLifecycleState.resumed && _appWasPaused) {
      _appWasPaused = false;
      _game.resumeEngine();
    }
  }

  bool _appWasPaused = false;

  Future<void> _startSession() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final success = await gameProvider.startSession();
    if (success && mounted) {
      setState(() {
        _sessionStarted = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Future<void> _runnerSubmitRewardsAndAds() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final eco = _game.economyManager;

    final success = await gameProvider.submitScore(
      score: eco.score,
      coinsCollected: eco.coinsCollected,
      distanceMeters: eco.distanceMeters,
    );
    if (!mounted) return;

    if (success) {
      final boost = gameProvider.lastGameBoostAward;
      if (boost != null) {
        final l = AppLocalizations.of(context);
        final reward = gameProvider.lastReward ?? eco.catoshiEarned;
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: Text(l.gameRewardBoostBonusTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.gameRewardRunnerSummary('$reward'),
                    textAlign: TextAlign.center,
                  ),
                  ...gameBoostBonusSection(ctx, l, boost),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.commonOk),
              ),
            ],
          ),
        );
      }
    }

    if (!mounted) return;
    AdService().showInterstitialAd(context);
    if (mounted) {
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
    }
  }

  void _handleGameOver() {
    unawaited(_runnerSubmitRewardsAndAds());
  }

  void _handlePlayAgain() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Start a new backend session for the next game
    await gameProvider.startSession();

    _game.restart();
  }

  void _handleExit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _game.onGameOver = _handleGameOver;

    if (!_sessionStarted) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF9800)),
              SizedBox(height: 16),
              Text(
                'Loading CatCoin Runner...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: GameWidget<RunnerGame>(
        game: _game,
        autofocus: true,
        overlayBuilderMap: {
          'Hud': (context, game) => GameHud(
                game: game,
                onPause: () => game.pauseGame(),
              ),
          'GameOver': (context, game) => GameOverOverlay(
                game: game,
                onPlayAgain: _handlePlayAgain,
                onExit: _handleExit,
              ),
          'Pause': (context, game) => PauseOverlay(
                onResume: () => game.resumeGame(),
                onQuit: _handleExit,
              ),
        },
        initialActiveOverlays: const ['Hud'],
      ),
    );
  }
}


