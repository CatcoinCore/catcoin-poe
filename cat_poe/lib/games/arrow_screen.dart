import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/mining_provider.dart';
import '../services/ad_service.dart';
import '../services/game_sfx_service.dart';
import '../utils/game_cooldown_format.dart';
import '../utils/game_reward_feedback.dart';
import '../utils/game_screen_capture_guard.dart';
import '../utils/game_session_gate.dart';
import 'arrow_escape/arrow_escape_board_painter.dart';
import 'arrow_escape/arrow_escape_engine.dart';
import 'arrow_escape/arrow_escape_generator.dart';
import 'arrow_escape/arrow_escape_slide_math.dart';

/// Polyline grid arrows with **random solvable layouts** each round (every arrow
/// ≥ 2 cells). Tap triggers slide-out animation or a bump when blocked.
class ArrowScreen extends StatefulWidget {
  const ArrowScreen({super.key});

  @override
  State<ArrowScreen> createState() => _ArrowScreenState();
}

class _ArrowScreenState extends State<ArrowScreen>
    with GameScreenCaptureGuard, SingleTickerProviderStateMixin {
  static const int _maxLives = 3;
  static const int _fallbackReward = 30;

  final Random _rng = Random();

  ArrowEscapeEngine? _engine;
  int _paintRevision = 0;
  int _difficultyLevel = 0;
  int _headStyleIndex = 0;

  late final AnimationController _slideCtrl;

  int? _slideArrowIndex;
  bool _slideSuccess = false;
  int? _pendingEscapeArrowId;
  bool _interactionLocked = false;
  double _slideTravelMaxPx = 0.0;

  double _lastCellW = 1;
  double _lastCellH = 1;

  int _arrowTaps = 0;

  bool _isGameOver = false;
  bool _hasWon = false;
  bool _isSubmitting = false;
  bool _resolutionBusy = false;

  Timer? _cooldownUiTimer;

  double? get _slideAlongPathTravelPx {
    if (!_interactionLocked || _slideArrowIndex == null) {
      return null;
    }
    final t = _slideCtrl.value;
    if (_slideSuccess) {
      return t * _slideTravelMaxPx;
    } else {
      return sin(pi * t) * _slideTravelMaxPx;
    }
  }

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onSlideComplete();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'ARROW')) return;
      if (!mounted) return;
      await _startSession();
      if (!mounted) return;
      await _loadDifficulty();
      if (!mounted) return;
      AdService().loadInterstitialAd(context);
      _beginRound(reset: true);
    });
  }

  Future<void> _loadDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _difficultyLevel = prefs.getInt('arrow_escape_difficulty') ?? 0;
    });
  }

  Future<void> _incrementDifficulty() async {
    _difficultyLevel++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('arrow_escape_difficulty', _difficultyLevel);
  }

  @override
  void dispose() {
    _cooldownUiTimer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onSlideComplete() {
    if (!mounted || !_interactionLocked) return;
    final eng = _engine;
    if (eng == null) return;

    if (_slideSuccess && _pendingEscapeArrowId != null) {
      eng.tryEscapeArrowByIndex(_pendingEscapeArrowId!);
      _paintRevision++;
      _pendingEscapeArrowId = null;
      if (eng.isClear) {
        _finishGame(won: true);
      }
    } else if (!_slideSuccess) {
      eng.loseLife();
      _paintRevision++;
      if (eng.lives <= 0) {
        _finishGame(won: false);
      }
    }

    _slideArrowIndex = null;
    _slideSuccess = false;
    _interactionLocked = false;
    _slideCtrl.reset();
    if (mounted) setState(() {});
  }

  Future<void> _startSession() async {
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.startSession();
  }

  void _beginRound({bool reset = false}) {
    _slideCtrl.stop();
    _slideCtrl.reset();
    _slideArrowIndex = null;
    _interactionLocked = false;
    _pendingEscapeArrowId = null;

    if (reset) {
      _headStyleIndex = _rng.nextInt(3);
    }
    _engine = ArrowEscapeGenerator.generate(_rng, maxLives: _maxLives, difficultyLevel: _difficultyLevel);
    if (reset) {
      _arrowTaps = 0;
      _isGameOver = false;
      _hasWon = false;
    }
    _paintRevision++;
    if (mounted) setState(() {});
  }

  void _onCellTap(int r, int c) {
    final engine = _engine;
    if (_interactionLocked || _isGameOver || engine == null) return;
    final id = engine.arrowIdAt(r, c);
    if (id == null) return;

    final cw = _lastCellW;
    final ch = _lastCellH;
    if (cw <= 0 || ch <= 0) return;

    _arrowTaps++;

    if (engine.canEscapeArrow(id)) {
      HapticFeedback.lightImpact();
      GameSfxService.instance.play(GameSfx.slide, volume: 0.46);
      final steps = arrowRigidExitSteps(engine, id);
      final dir = engine.headDirForArrow(id)!;
      final cells = engine.cellsForArrow(id)!;
      final travelPx = arrowEscapeSlideTravelPx(
        cells: cells,
        headDir: dir,
        cellW: cw,
        cellH: ch,
        exitCells: steps,
      );
      _slideTravelMaxPx = travelPx;
      _slideArrowIndex = id;
      _pendingEscapeArrowId = id;
      _slideSuccess = true;
      _interactionLocked = true;
      final ms = (280 + travelPx * 0.55).round().clamp(320, 980);
      _slideCtrl.duration = Duration(milliseconds: ms);
      _slideCtrl.forward(from: 0);
    } else {
      HapticFeedback.heavyImpact();
      GameSfxService.instance.play(GameSfx.bump, volume: 0.58);
      final clearRay = arrowHeadRayClearSteps(engine, id);
      final fracCells = clearRay == 0 ? 0.28 : clearRay + 0.38;
      _slideTravelMaxPx = fracCells * min(cw, ch);
      _slideArrowIndex = id;
      _slideSuccess = false;
      _pendingEscapeArrowId = null;
      _interactionLocked = true;
      _slideCtrl.duration = const Duration(milliseconds: 440);
      _slideCtrl.forward(from: 0);
    }
    setState(() {});
  }

  void _finishGame({required bool won}) {
    final sfx = GameSfxService.instance;
    if (won) {
      sfx.play(GameSfx.win, volume: 0.72);
    } else {
      sfx.play(GameSfx.lose, volume: 0.52);
    }
    setState(() {
      _isGameOver = true;
      _hasWon = won;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_resolveAfterGameEnd(won: won));
    });
  }

  Future<void> _resolveAfterGameEnd({required bool won}) async {
    if (_resolutionBusy) return;
    _resolutionBusy = true;
    try {
      final gp = Provider.of<GameProvider>(context, listen: false);
      await gp.fetchStatus();
      if (!mounted) return;
      if (won) {
        await _incrementDifficulty();
        if (!mounted) return;
        await AdService().showRewardGateAd(context, gameType: 'ARROW');
        if (!mounted) return;
        await _submitResult();
      }
      if (mounted) {
        setState(() {});
        _maybeStartCooldownTicker();
      }
    } finally {
      _resolutionBusy = false;
    }
  }

  int _submitScore() {
    final engine = _engine;
    if (engine == null) return 0;
    final base = engine.initialArrowCount * 1000;
    final lifeBonus = engine.lives * 200;
    final tapPenalty = _arrowTaps * 15;
    return (base + lifeBonus - tapPenalty).clamp(1, 1 << 30);
  }

  Future<void> _submitResult() async {
    final messenger = ScaffoldMessenger.of(context);
    final mining = Provider.of<MiningProvider>(context, listen: false);
    final gp = Provider.of<GameProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    final success = await gp.submitScore(
      score: _submitScore(),
      coinsCollected: _fallbackReward,
      gameType: 'ARROW',
    );

    if (!context.mounted) return;

    if (success) {
      mining.fetchStats();
      await gp.fetchStatus();
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showRewardDialog(
          gp.lastReward ?? _fallbackReward,
          gp.lastGameBoostAward,
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

    if (!context.mounted) return;
    setState(() => _isSubmitting = false);
    _maybeStartCooldownTicker();
  }

  void _showRewardDialog(int catoshi, GameBoostAward? boost) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
        title: Text(l10n.gameYouWin, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.gameArrowSuccess(catoshi.toString()),
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

  void _maybeStartCooldownTicker() {
    _cooldownUiTimer?.cancel();
    if (!_isGameOver) return;
    final st =
        Provider.of<GameProvider>(context, listen: false).statusMap['ARROW'];
    if (st == null || st.canPlay) return;

    _cooldownUiTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final gp = Provider.of<GameProvider>(context, listen: false);
      final s = gp.statusMap['ARROW'];
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

  Future<void> _onPlayAgain() async {
    if (_isSubmitting || _resolutionBusy || _interactionLocked) return;
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.fetchStatus();
    if (!mounted) return;
    final st = gp.statusMap['ARROW'];
    if (st != null && !st.canPlay) {
      setState(() {});
      _maybeStartCooldownTicker();
      return;
    }
    _cooldownUiTimer?.cancel();
    await _startSession();
    if (!mounted) return;
    _beginRound(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reward =
        Provider.of<GameProvider>(context).statusMap['ARROW']?.reward;
    final engine = _engine;

    return Scaffold(
      backgroundColor: const Color(0xFF080C18),
      appBar: AppBar(
        title: Text(l.gamesArrowTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _buildHeader(l, reward ?? _fallbackReward, engine),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, slotConstraints) =>
                    _buildArrowBoardArea(context, l, slotConstraints, engine),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l,
    int reward,
    ArrowEscapeEngine? engine,
  ) {
    final remaining = engine?.arrowsRemaining ?? 0;
    final total = engine?.initialArrowCount ?? 0;
    final lives = engine?.lives ?? _maxLives;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              l.gameWinReward(reward.toString()),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Badge(
                icon: Icons.navigation,
                color: Colors.cyanAccent,
                label: l.gameArrowScore('$remaining', '$total'),
              ),
              _Badge(
                icon: Icons.favorite,
                color: Colors.redAccent,
                label: l.gameArrowLives('$lives'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Playfield fills [Expanded]; [slot] is the tight area from outer + inner [LayoutBuilder].
  Widget _buildArrowBoardArea(
    BuildContext context,
    AppLocalizations l,
    BoxConstraints slot,
    ArrowEscapeEngine? engine,
  ) {
    if (engine == null || _isGameOver) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(child: _buildEndArea(l)),
      );
    }

    final mq = MediaQuery.sizeOf(context);
    var slotW = slot.maxWidth;
    var slotH = slot.maxHeight;
    if (!slotW.isFinite || slotW < 56) slotW = mq.width;
    if (!slotH.isFinite || slotH < 56) slotH = mq.shortestSide * 0.85;

    final rows = engine.rows;
    final cols = engine.cols;

    final budgetW = max(80.0, slotW - 16);
    final budgetH = max(80.0, slotH - 24);

    final cellByW = budgetW / cols;
    final cellByH = budgetH / rows;
    var cell = min(cellByW, cellByH);
    if (!cell.isFinite || cell <= 0) {
      cell = 14.0;
    } else if (cell < 4.0) {
      cell = 4.0;
    }

    final gridW = cell * cols;
    final gridH = cell * rows;
    _lastCellW = cell;
    _lastCellH = cell;

    final board = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SizedBox(
        width: gridW,
        height: gridH,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _interactionLocked
              ? null
              : (d) {
                  final lp = d.localPosition;
                  final lx = lp.dx;
                  final ly = lp.dy;
                  if (lx < 0 || ly < 0 || lx >= gridW || ly >= gridH) {
                    return;
                  }
                  final ci = (lx / cell).floor().clamp(0, engine.cols - 1);
                  final ri = (ly / cell).floor().clamp(0, engine.rows - 1);
                  _onCellTap(ri, ci);
                },
          child: CustomPaint(
            painter: ArrowEscapeBoardPainter(
              engine: engine,
              cellW: cell,
              cellH: cell,
              revision: _paintRevision,
              paintBleed: 0,
              slidingArrowIndex: _slideArrowIndex,
              slideTravelPx: _slideAlongPathTravelPx,
              headStyleIndex: _headStyleIndex,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: slotW,
        height: slotH,
        child: Center(
          child: board,
        ),
      ),
    );
  }

  Widget _buildEndArea(AppLocalizations l) {
    if (!_isGameOver) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildEndCard(l);
  }

  Widget _buildEndCard(AppLocalizations l) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final st = gp.statusMap['ARROW'];
        final canPlayAgain = (st == null || st.canPlay) &&
            !_isSubmitting &&
            !_resolutionBusy &&
            !_interactionLocked;
        final remaining = formatGameCooldownRemaining(st?.cooldownUntil);
        final showCooldownMsg = st != null && !st.canPlay;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 96,
                color: _hasWon ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _hasWon ? l.gameYouWin : l.gameArrowGameOver,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.gameArrowFinalScore('$_arrowTaps'),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              if (showCooldownMsg)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    remaining != null
                        ? l.gameCooldownComeBack(remaining)
                        : l.gameCooldownLimitReached,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: canPlayAgain ? _onPlayAgain : null,
                icon: const Icon(Icons.replay),
                label: Text(l.gamePlayAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.shade400,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              if (_isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
