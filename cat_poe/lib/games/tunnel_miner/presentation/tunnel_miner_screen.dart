import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:cat_poe/l10n/app_localizations.dart';

import '../../../providers/game_provider.dart';
import '../../../providers/mining_provider.dart';
import '../../../services/ad_service.dart';
import '../../../utils/game_reward_feedback.dart';
import '../../../utils/game_screen_capture_guard.dart';
import '../../../utils/game_session_gate.dart';
import '../../../services/game_sfx_service.dart';
import '../data/tunnel_miner_models.dart';
import '../game/catcoin_tunnel_miner_game.dart';
import '../game/miner_world.dart';
import 'widgets/tunnel_miner_hud.dart';
import 'widgets/tunnel_miner_intro_overlay.dart';
import 'widgets/tunnel_miner_pause_overlay.dart';
import 'widgets/tunnel_miner_result_overlay.dart';

/// Hosts [CatcoinTunnelMinerGame] and wires the same session / submit flow as Runner.
class TunnelMinerScreen extends StatefulWidget {
  const TunnelMinerScreen({super.key});

  @override
  State<TunnelMinerScreen> createState() => _TunnelMinerScreenState();
}

class _TunnelMinerScreenState extends State<TunnelMinerScreen>
    with WidgetsBindingObserver, GameScreenCaptureGuard {
  late final CatcoinTunnelMinerGame _game;
  bool _sessionStarted = false;
  bool _appWasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = CatcoinTunnelMinerGame();
    _game.onRunEnded = _handleRunEnded;
    _game.mine.sfxSink = _playMinerSfx;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'MINER')) return;
      if (!mounted) return;
      await _startSession();
      if (mounted) {
        AdService().loadInterstitialAd(context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_game.mine.phase == TunnelRunPhase.playing) {
        _game.pauseRun();
        _appWasPaused = true;
      }
    } else if (state == AppLifecycleState.resumed && _appWasPaused) {
      _appWasPaused = false;
      _game.resumeEngine();
      if (_game.mine.phase == TunnelRunPhase.paused) {
        _game.resumeRun();
      }
    }
  }

  Future<void> _startSession() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final ok = await gameProvider.startSession();
    if (ok && mounted) {
      setState(() => _sessionStarted = true);
    }
  }

  void _handleRunEnded() {
    unawaited(_submitRewardsAndAds());
  }

  Future<void> _submitRewardsAndAds() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final s = _game.mine.stats;

    final success = await gameProvider.submitScore(
      score: s.score,
      coinsCollected: s.shards,
      distanceMeters: s.maxDepth,
      gameType: 'MINER',
    );
    if (!mounted) return;

    if (success) {
      final boost = gameProvider.lastGameBoostAward;
      if (boost != null) {
        final l = AppLocalizations.of(context);
        final reward = gameProvider.lastReward ?? s.shards;
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
                    l.gameRewardMinerSummary('$reward'),
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

    if (mounted) {
      AdService().showInterstitialAd(context);
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
    }
  }

  Future<void> _handlePlayAgain() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final ok = await gameProvider.startSession();
    if (!ok || !mounted) return;
    _game.beginFreshRunAfterPlayAgain();
  }

  void _handleExit() {
    Navigator.of(context).pop();
  }

  void _playMinerSfx(TunnelMinerSfxKind kind) {
    final sfx = GameSfxService.instance;
    switch (kind) {
      case TunnelMinerSfxKind.dig:
        sfx.play(GameSfx.softTap, volume: 0.42);
        break;
      case TunnelMinerSfxKind.stride:
        sfx.play(GameSfx.softTap, volume: 0.52);
        break;
      case TunnelMinerSfxKind.mineAdjacent:
        sfx.play(GameSfx.bump, volume: 0.38);
        break;
      case TunnelMinerSfxKind.collectOre:
        sfx.play(GameSfx.coin, volume: 0.6);
        break;
      case TunnelMinerSfxKind.runWin:
        sfx.play(GameSfx.win, volume: 0.74);
        break;
      case TunnelMinerSfxKind.runLose:
        sfx.play(GameSfx.lose, volume: 0.52);
        break;
    }
  }

  @override
  void dispose() {
    _game.mine.sfxSink = null;
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!_sessionStarted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF9800)),
              const SizedBox(height: 16),
              Text(
                l.tunnelMinerLoading,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SizedBox.expand(
        child: GameWidget<CatcoinTunnelMinerGame>(
          game: _game,
          autofocus: true,
          overlayBuilderMap: {
            'Intro': (context, game) => TunnelMinerIntroOverlay(game: game),
            'Hud': (context, game) => TunnelMinerHud(
                  game: game,
                  onPause: game.pauseRun,
                ),
            'Pause': (context, game) => TunnelMinerPauseOverlay(
                  onResume: game.resumeRun,
                  onQuit: _handleExit,
                ),
            'Result': (context, game) => TunnelMinerResultOverlay(
                  key: ValueKey(game.resultOverlayEpoch),
                  game: game,
                  onPlayAgain: _handlePlayAgain,
                  onExit: _handleExit,
                ),
          },
          initialActiveOverlays: const ['Intro'],
        ),
      ),
    );
  }
}
