import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/game_provider.dart';
import '../../providers/mining_provider.dart';
import '../../services/ad_service.dart';
import '../../services/game_sfx_service.dart';
import '../../utils/game_reward_feedback.dart';
import '../../utils/game_screen_capture_guard.dart';
import '../../utils/game_session_gate.dart';
import 'tile_swap_game.dart';

/// Swap-to-match grid puzzle (Flame). Reward when score reaches the goal (round ends
/// immediately) or when moves run out (`gameType`: `TILE_SWAP`).
class TileSwapScreen extends StatefulWidget {
  const TileSwapScreen({super.key});

  @override
  State<TileSwapScreen> createState() => _TileSwapScreenState();
}

class _TileSwapScreenState extends State<TileSwapScreen>
    with GameScreenCaptureGuard {
  static const int _fallbackReward = 25;

  late final TileSwapGame _game;
  bool _sessionStarted = false;
  bool _endHandled = false;
  bool _isSubmitting = false;
  bool _resolutionBusy = false;

  @override
  void initState() {
    super.initState();
    _game = TileSwapGame();
    _game.onIllegalSwap = () =>
        GameSfxService.instance.play(GameSfx.bump, volume: 0.62);
    _game.onLegalSwapCommitted = () =>
        GameSfxService.instance.play(GameSfx.slide, volume: 0.34);
    _game.onMatchClear = () =>
        GameSfxService.instance.play(GameSfx.merge, volume: 0.48);
    _game.onRoundEnded = _onRoundEnded;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'TILE_SWAP')) {
        return;
      }
      if (!mounted) return;
      await _startSession();
      if (mounted) {
        AdService().loadInterstitialAd(context);
      }
    });
  }

  Future<void> _startSession() async {
    final gp = Provider.of<GameProvider>(context, listen: false);
    final ok = await gp.startSession();
    if (ok && mounted) {
      setState(() => _sessionStarted = true);
    }
  }

  void _onRoundEnded() {
    if (_endHandled || !mounted) return;
    _endHandled = true;
    unawaited(_resolveRoundComplete());
  }

  Future<void> _resolveRoundComplete() async {
    if (_resolutionBusy) return;
    _resolutionBusy = true;
    try {
      final gp = Provider.of<GameProvider>(context, listen: false);
      await gp.fetchStatus();
      if (!mounted) return;

      if (_game.board.reachedTarget) {
        await AdService().showRewardGateAd(context, gameType: 'TILE_SWAP');
        if (!mounted) return;
        await _submitWin();
      } else {
        if (!mounted) return;
        GameSfxService.instance.play(GameSfx.lose, volume: 0.46);
        final l = AppLocalizations.of(context);
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: Text(l.gamesTileSwapTitle, textAlign: TextAlign.center),
            content: Text(
              l.gameTileSwapLossBody(
                '${_game.board.score}',
                '${_game.board.targetScore}',
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.commonOk),
              ),
            ],
          ),
        );
        if (mounted) {
          AdService().showInterstitialAd(context);
        }
      }

      if (mounted) setState(() {});
    } finally {
      _resolutionBusy = false;
    }
  }

  Future<void> _submitWin() async {
    if (_isSubmitting) return;
    final messenger = ScaffoldMessenger.of(context);
    final mining = Provider.of<MiningProvider>(context, listen: false);
    final gp = Provider.of<GameProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    final success = await gp.submitScore(
      score: _game.board.score,
      coinsCollected: _fallbackReward,
      gameType: 'TILE_SWAP',
    );

    if (!context.mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      GameSfxService.instance.play(GameSfx.win, volume: 0.72);
      mining.fetchStats();
      await gp.fetchStatus();
      if (!context.mounted) return;
      final boost = gp.lastGameBoostAward;
      final reward = gp.lastReward ?? _fallbackReward;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context);
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
            title: Text(l.gameYouWin, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.gameTileSwapSuccess('$reward'),
                    textAlign: TextAlign.center,
                  ),
                  if (boost != null) ...gameBoostBonusSection(ctx, l, boost),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.commonOk),
              ),
            ],
          ),
        );
      });
    } else if (gp.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(gp.error!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _playAgain() async {
    final gp = Provider.of<GameProvider>(context, listen: false);
    final ok = await gp.startSession();
    if (!ok || !mounted) return;
    setState(() {
      _endHandled = false;
    });
    _game.newRound();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (!_sessionStarted) {
      return Scaffold(
        backgroundColor: const Color(0xFF121822),
        appBar: AppBar(
          title: Text(l.gamesTileSwapTitle),
          backgroundColor: const Color(0xFF1E2635),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121822),
      appBar: AppBar(
        title: Text(l.gamesTileSwapTitle),
        backgroundColor: const Color(0xFF1E2635),
        actions: [
          if (_game.board.reachedTarget &&
              (_game.board.isTerminal || _endHandled))
            TextButton(
              onPressed: _isSubmitting ? null : _playAgain,
              child: Text(
                l.gamePlayAgain,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _game.hudRevision,
            builder: (context, _, __) {
              final b = _game.board;
              final hitTarget = b.reachedTarget;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _HudChip(
                        label: l.gameTileSwapHudScore('${b.score}'),
                        emphasize: hitTarget,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HudChip(
                        label: l.gameTileSwapHudMoves('${b.movesRemaining}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HudChip(
                        label: l.gameTileSwapHudTarget('${b.targetScore}'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: GameWidget<TileSwapGame>(
              game: _game,
              autofocus: true,
            ),
          ),
          if (_game.board.reachedTarget &&
              (_game.board.isTerminal || _endHandled))
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _playAgain,
                    child: Text(l.gamePlayAgain),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    this.emphasize = false,
  });

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasize
            ? Colors.teal.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize
              ? Colors.tealAccent.withValues(alpha: 0.7)
              : Colors.white24,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: emphasize ? Colors.tealAccent.shade100 : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
