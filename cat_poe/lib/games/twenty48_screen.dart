import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'twenty48_game_storage.dart';

/// Classic 4×4 2048. Reach tile 2048 to qualify for Catoshi; payout scales with
/// your **final** score when the run ends (server: base reward + score bonus).
class Twenty48Screen extends StatefulWidget {
  const Twenty48Screen({super.key});

  @override
  State<Twenty48Screen> createState() => _Twenty48ScreenState();
}

enum _SlideDir { up, down, left, right }

/// One numbered tile with a stable [id] so [AnimatedPositioned] can animate moves.
class _BoardTile {
  _BoardTile({required this.id, required this.value});

  final int id;
  int value;
}

class _Twenty48ScreenState extends State<Twenty48Screen>
    with GameScreenCaptureGuard {
  static const int _gridSize = 4;
  static const int _winTile = 2048;
  /// Shown on the games list / header when admin reward is unknown (base only).
  static const int _displayRewardFallback = 75;

  static const double _cellGap = 8;
  static const double _boardPad = 8;
  static const Duration _tileSlideDuration = Duration(milliseconds: 135);
  /// Shared tween so [TweenAnimationBuilder] does not restart every [setState].
  static final Tween<double> _tileSpawnScaleTween =
      Tween<double>(begin: 0.88, end: 1.0);

  final Random _random = Random();
  int _nextTileId = 1;
  late List<List<_BoardTile?>> _grid;
  int _score = 0;
  int _bestTile = 0;
  bool _hasReachedTarget = false;
  bool _rewardGranted = false;
  bool _isGameOver = false;
  bool _isSubmitting = false;
  bool _resolutionBusy = false;
  Timer? _cooldownUiTimer;

  /// Accumulated drag for resolving swipe direction.
  double _panDx = 0;
  double _panDy = 0;

  @override
  void initState() {
    super.initState();
    _grid = _emptyGrid();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await ensureGamePlayAllowed(context, gameType: 'TWENTY48')) {
        return;
      }
      if (!mounted) return;
      await _startSession();
      if (!mounted) return;
      AdService().loadInterstitialAd(context);
      final restored = await _restoreFromDisk();
      if (!mounted) return;
      if (!restored) {
        _resetBoard();
      } else {
        if (_isGameOver &&
            _bestTile >= _winTile &&
            !_rewardGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_onGameFinished());
          });
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_persistGame());
    _cooldownUiTimer?.cancel();
    super.dispose();
  }

  List<List<_BoardTile?>> _emptyGrid() => List.generate(
        _gridSize,
        (_) => List<_BoardTile?>.filled(_gridSize, null),
      );

  int _cellValue(_BoardTile? t) => t?.value ?? 0;

  Future<void> _startSession() async {
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.startSession();
  }

  void _resetBoard() {
    setState(() {
      _nextTileId = 1;
      _grid = _emptyGrid();
      _score = 0;
      _bestTile = 0;
      _hasReachedTarget = false;
      _rewardGranted = false;
      _isGameOver = false;
      _spawnTile();
      _spawnTile();
    });
    _schedulePersist();
  }

  void _spawnTile() {
    final empties = <Point<int>>[];
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_grid[r][c] == null) empties.add(Point<int>(r, c));
      }
    }
    if (empties.isEmpty) return;
    final p = empties[_random.nextInt(empties.length)];
    final v = _random.nextDouble() < 0.9 ? 2 : 4;
    _grid[p.x][p.y] = _BoardTile(id: _nextTileId++, value: v);
  }

  bool _slide(_SlideDir dir) {
    if (_isGameOver) return false;
    final before = _gridSnapshot();
    var mergeCount = 0;
    switch (dir) {
      case _SlideDir.left:
        for (int r = 0; r < _gridSize; r++) {
          final merged = _mergeTilesLine(_grid[r]);
          mergeCount += merged.merges;
          _grid[r] = merged.line;
        }
        break;
      case _SlideDir.right:
        for (int r = 0; r < _gridSize; r++) {
          final reversed = _grid[r].reversed.toList();
          final merged = _mergeTilesLine(reversed);
          mergeCount += merged.merges;
          _grid[r] = merged.line.reversed.toList();
        }
        break;
      case _SlideDir.up:
        for (int c = 0; c < _gridSize; c++) {
          final col = [for (int r = 0; r < _gridSize; r++) _grid[r][c]];
          final merged = _mergeTilesLine(col);
          mergeCount += merged.merges;
          for (int r = 0; r < _gridSize; r++) {
            _grid[r][c] = merged.line[r];
          }
        }
        break;
      case _SlideDir.down:
        for (int c = 0; c < _gridSize; c++) {
          final col =
              [for (int r = 0; r < _gridSize; r++) _grid[r][c]].reversed.toList();
          final merged = _mergeTilesLine(col);
          mergeCount += merged.merges;
          final restored = merged.line.reversed.toList();
          for (int r = 0; r < _gridSize; r++) {
            _grid[r][c] = restored[r];
          }
        }
        break;
    }
    final changed = !_gridsEqual(before, _gridSnapshot());
    if (changed) {
      final sfx = GameSfxService.instance;
      if (mergeCount > 0) {
        sfx.play(GameSfx.merge, volume: 0.55);
      } else {
        sfx.play(GameSfx.slide, volume: 0.34);
      }
      _spawnTile();
      _refreshBestTile();
      if (!_hasReachedTarget && _bestTile >= _winTile) {
        _hasReachedTarget = true;
        HapticFeedback.mediumImpact();
        sfx.play(GameSfx.coin, volume: 0.48);
      }
      if (!_hasMoves()) {
        _isGameOver = true;
        if (_bestTile >= _winTile) {
          sfx.play(GameSfx.softTap, volume: 0.44);
        } else {
          sfx.play(GameSfx.lose, volume: 0.42);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_onGameFinished());
        });
      }
      _schedulePersist();
    }
    if (mounted && changed) setState(() {});
    return changed;
  }

  /// Slide non-null tiles to the start of the line, merging adjacent equal pairs once.
  ({List<_BoardTile?> line, int merges}) _mergeTilesLine(
    List<_BoardTile?> source,
  ) {
    final tiles = source.whereType<_BoardTile>().toList();
    final out = <_BoardTile?>[];
    var merges = 0;
    for (int i = 0; i < tiles.length; i++) {
      if (i + 1 < tiles.length && tiles[i].value == tiles[i + 1].value) {
        merges++;
        final merged = tiles[i].value * 2;
        tiles[i].value = merged;
        _score += merged;
        out.add(tiles[i]);
        i += 1;
      } else {
        out.add(tiles[i]);
      }
    }
    while (out.length < _gridSize) {
      out.add(null);
    }
    return (line: out, merges: merges);
  }

  List<List<int>> _gridSnapshot() => [
        for (final row in _grid)
          [for (final t in row) _cellValue(t)]
      ];

  bool _gridsEqual(List<List<int>> a, List<List<int>> b) {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  void _refreshBestTile() {
    int best = 0;
    for (final row in _grid) {
      for (final t in row) {
        final v = _cellValue(t);
        if (v > best) best = v;
      }
    }
    _bestTile = best;
  }

  bool _hasMoves() {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        final v = _cellValue(_grid[r][c]);
        if (v == 0) return true;
        if (c + 1 < _gridSize &&
            v == _cellValue(_grid[r][c + 1])) {
          return true;
        }
        if (r + 1 < _gridSize &&
            v == _cellValue(_grid[r + 1][c])) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _onGameFinished() async {
    await _handleGameOver();
    if (!mounted) return;
    if (_bestTile >= _winTile && !_rewardGranted) {
      await _grantRewardOnce();
    }
  }

  Future<void> _grantRewardOnce() async {
    if (_rewardGranted || _resolutionBusy) return;
    _resolutionBusy = true;
    try {
      await AdService().showRewardGateAd(context, gameType: 'TWENTY48');
      if (!mounted) return;
      await _submitResult();
    } finally {
      _resolutionBusy = false;
    }
  }

  Future<void> _handleGameOver() async {
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.fetchStatus();
    if (!mounted) return;
    setState(() {});
    _schedulePersist();
    _maybeStartCooldownTicker();
  }

  Future<void> _submitResult() async {
    final messenger = ScaffoldMessenger.of(context);
    final mining = Provider.of<MiningProvider>(context, listen: false);
    final gp = Provider.of<GameProvider>(context, listen: false);

    setState(() => _isSubmitting = true);

    final success = await gp.submitScore(
      score: _score,
      coinsCollected: 0,
      distanceMeters: _bestTile,
      gameType: 'TWENTY48',
    );

    if (!context.mounted) return;

    if (success) {
      _rewardGranted = true;
      HapticFeedback.mediumImpact();
      GameSfxService.instance.play(GameSfx.win, volume: 0.7);
      mining.fetchStats();
      await gp.fetchStatus();
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showRewardDialog(
          gp.lastReward ?? 0,
          gp.lastGameBoostAward,
          _score,
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
    _schedulePersist();
    _maybeStartCooldownTicker();
  }

  Twenty48SavedGame _captureSavedGame() {
    final grid = <List<Map<String, int>?>>[
      for (final row in _grid)
        [
          for (final t in row)
            t == null ? null : <String, int>{'id': t.id, 'value': t.value},
        ],
    ];
    return Twenty48SavedGame(
      schemaVersion: Twenty48SavedGame.currentSchema,
      nextTileId: _nextTileId,
      score: _score,
      bestTile: _bestTile,
      hasReachedTarget: _hasReachedTarget,
      rewardGranted: _rewardGranted,
      isGameOver: _isGameOver,
      grid: grid,
    );
  }

  Future<void> _persistGame() async {
    try {
      await Twenty48GameStorage.save(_captureSavedGame());
    } catch (_) {}
  }

  void _schedulePersist() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_persistGame());
    });
  }

  Future<bool> _restoreFromDisk() async {
    try {
      final game = await Twenty48GameStorage.load();
      if (game == null || !game.validate(gridSize: _gridSize)) {
        if (game != null) await Twenty48GameStorage.clear();
        return false;
      }
      if (!mounted) return false;
      setState(() {
        _nextTileId = game.nextTileId;
        _score = game.score;
        _bestTile = game.bestTile;
        _hasReachedTarget = game.hasReachedTarget;
        _rewardGranted = game.rewardGranted;
        _isGameOver = game.isGameOver;
        _grid = List.generate(_gridSize, (r) {
          return List.generate(_gridSize, (c) {
            final cell = game.grid[r][c];
            if (cell == null) return null;
            return _BoardTile(id: cell['id']!, value: cell['value']!);
          });
        });
        _refreshBestTile();
      });
      return true;
    } catch (_) {
      await Twenty48GameStorage.clear();
      return false;
    }
  }

  Future<void> _confirmExitGame() async {
    await _persistGame();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.gameTwenty48ExitTitle),
        content: Text(l.gameTwenty48ExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.gameTwenty48Stay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.gameTwenty48Leave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showRewardDialog(int catoshi, GameBoostAward? boost, int finalScore) {
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
                l10n.gameTwenty48Success(catoshi.toString()),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gameSudokuScore(finalScore.toString()),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(ctx).hintColor,
                  fontWeight: FontWeight.w600,
                ),
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
    if (!_isGameOver && !_rewardGranted) return;
    final st =
        Provider.of<GameProvider>(context, listen: false).statusMap['TWENTY48'];
    if (st == null || st.canPlay) return;

    _cooldownUiTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final gp = Provider.of<GameProvider>(context, listen: false);
      final s = gp.statusMap['TWENTY48'];
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
    if (_isSubmitting || _resolutionBusy) return;
    final gp = Provider.of<GameProvider>(context, listen: false);
    await gp.fetchStatus();
    if (!mounted) return;
    final st = gp.statusMap['TWENTY48'];
    if (st != null && !st.canPlay) {
      setState(() {});
      _maybeStartCooldownTicker();
      return;
    }
    _cooldownUiTimer?.cancel();
    await _startSession();
    if (!mounted) return;
    _resetBoard();
  }

  static const double _velocityThreshold = 115;
  static const double _distanceThreshold = 16;

  /// Maps a 2D vector to exactly one axis-aligned swipe using 45° sectors.
  _SlideDir _dirFromVector(double dx, double dy) {
    final angle = atan2(dy, dx);
    const q = pi / 4;
    if (angle >= -q && angle < q) return _SlideDir.right;
    if (angle >= q && angle < 3 * q) return _SlideDir.down;
    if (angle >= 3 * q || angle < -3 * q) return _SlideDir.left;
    return _SlideDir.up;
  }

  _SlideDir? _resolveSwipeDirection(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    final speed = sqrt(vx * vx + vy * vy);
    final dist = sqrt(_panDx * _panDx + _panDy * _panDy);

    if (dist >= _distanceThreshold) {
      return _dirFromVector(_panDx, _panDy);
    }
    if (speed >= _velocityThreshold) {
      return _dirFromVector(vx, vy);
    }
    return null;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isGameOver) return;
    final dir = _resolveSwipeDirection(details);
    _panDx = 0;
    _panDy = 0;
    if (dir == null) return;

    final moved = _slide(dir);
    if (moved) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isGameOver) return;
    _panDx += details.delta.dx;
    _panDy += details.delta.dy;
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reward =
        Provider.of<GameProvider>(context).statusMap['TWENTY48']?.reward;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExitGame());
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l.gamesTwenty48Title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(l, reward ?? _displayRewardFallback),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildBoard(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // flex: 0 so the board [Expanded] above gets all flexible height;
              // default Flexible(flex: 1) was splitting space 50/50 and shrinking the grid.
              Flexible(
                flex: 0,
                fit: FlexFit.loose,
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildActionRow(l),
                    const SizedBox(height: 12),
                    if (_isSubmitting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(AppLocalizations l, int reward) {
    return Column(
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreChip(label: l.gameTwenty48Score, value: '$_score'),
            _ScoreChip(label: l.gameTwenty48Best, value: '$_bestTile'),
          ],
        ),
        if (_hasReachedTarget && !_isGameOver) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l.gameTwenty48Reached2048,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoard() {
    final emptySlotColor =
        Theme.of(context).dividerColor.withValues(alpha: 0.38);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        if (_isGameOver) return;
        _panDx = 0;
        _panDy = 0;
      },
      onPanCancel: () {
        _panDx = 0;
        _panDy = 0;
      },
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        padding: const EdgeInsets.all(_boardPad),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inner =
                min(constraints.maxWidth, constraints.maxHeight);
            final cell =
                (inner - _cellGap * (_gridSize - 1)) / _gridSize;

            return SizedBox(
              width: inner,
              height: inner,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int r = 0; r < _gridSize; r++)
                    for (int c = 0; c < _gridSize; c++)
                      Positioned(
                        left: c * (cell + _cellGap),
                        top: r * (cell + _cellGap),
                        width: cell,
                        height: cell,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: emptySlotColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  for (int r = 0; r < _gridSize; r++)
                    for (int c = 0; c < _gridSize; c++)
                      if (_grid[r][c] != null)
                        AnimatedPositioned(
                          key: ValueKey<int>(_grid[r][c]!.id),
                          duration: _tileSlideDuration,
                          curve: Curves.easeOutCubic,
                          left: c * (cell + _cellGap),
                          top: r * (cell + _cellGap),
                          width: cell,
                          height: cell,
                          child: TweenAnimationBuilder<double>(
                            tween: _tileSpawnScaleTween,
                            duration: const Duration(milliseconds: 165),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: _Tile(value: _grid[r][c]!.value),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionRow(AppLocalizations l) {
    final gp = Provider.of<GameProvider>(context);
    final st = gp.statusMap['TWENTY48'];
    final canPlayAgain = (st == null || st.canPlay) &&
        !_isSubmitting &&
        !_resolutionBusy;
    final remaining = formatGameCooldownRemaining(st?.cooldownUntil);
    final showCooldownMsg = _isGameOver && st != null && !st.canPlay;
    return Column(
      children: [
        if (_isGameOver)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.gameTwenty48GameOver,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
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
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: canPlayAgain ? _onPlayAgain : null,
              icon: const Icon(Icons.refresh),
              label: Text(_isGameOver ? l.gamePlayAgain : l.gameTwenty48Restart),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.gameTwenty48SwipeHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value});

  final int value;

  // Standard 2048 palette extended for tiles beyond 2048.
  Color _bgFor(int v, BuildContext context) {
    if (v == 0) {
      return Theme.of(context).dividerColor.withValues(alpha: 0.4);
    }
    const palette = <int, Color>{
      2: Color(0xFFEEE4DA),
      4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179),
      16: Color(0xFFF59563),
      32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B),
      128: Color(0xFFEDCF72),
      256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850),
      1024: Color(0xFFEDC53F),
      2048: Color(0xFFEDC22E),
    };
    if (palette.containsKey(v)) return palette[v]!;
    // Beyond 2048 — keep getting darker / richer as the player keeps going.
    return const Color(0xFF3C3A32);
  }

  Color _fgFor(int v) =>
      v <= 4 ? const Color(0xFF776E65) : Colors.white;

  double _fontSizeFor(int v) {
    if (v < 100) return 32;
    if (v < 1000) return 26;
    if (v < 10000) return 22;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 45),
      decoration: BoxDecoration(
        color: _bgFor(value, context),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? const SizedBox.shrink()
          : Text(
              '$value',
              style: TextStyle(
                color: _fgFor(value),
                fontSize: _fontSizeFor(value),
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
