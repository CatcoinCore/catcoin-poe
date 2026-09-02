import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tile_swap_board.dart';

double _smoothStep(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return t * t * (3 - 2 * t);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

bool _v2Finite(Vector2 v) => v.x.isFinite && v.y.isFinite;

/// Flame host for Tile Swap — drag a tile onto an adjacent slot to swap.
class TileSwapGame extends FlameGame {
  TileSwapGame({Random? random}) : _random = random ?? Random() {
    board = TileSwapBoardModel.newGame(_random);
    boardLayer = TileSwapBoardComponent(gameRef: this);
  }

  final Random _random;

  late TileSwapBoardModel board;
  late TileSwapBoardComponent boardLayer;

  VoidCallback? onRoundEnded;

  VoidCallback? onIllegalSwap;
  VoidCallback? onLegalSwapCommitted;
  VoidCallback? onMatchClear;

  final ValueNotifier<int> hudRevision = ValueNotifier<int>(0);

  /// Plain, distinguishable fills (no gradients).
  static const List<Color> _palette = [
    Color(0xFFD32F2F),
    Color(0xFF388E3C),
    Color(0xFF1976D2),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFFFBC02D),
    Color(0xFF0097A7),
    Color(0xFF5D4037),
  ];

  static Color colorForKind(int kind) {
    final base = TileSwapBoardModel.tileMatchColor(kind);
    if (base < 0) return const Color(0xFF9E9E9E);
    return _palette[base % _palette.length];
  }

  @override
  Color backgroundColor() => const Color(0xFF121822);

  void newRound() {
    board = TileSwapBoardModel.newGame(_random);
    boardLayer.resetAnimationState();
    hudRevision.value++;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await world.add(boardLayer);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.visibleGameSize = size;
    const topHudReserve = 52.0;
    const horizontalPad = 16.0;
    final side = min(size.x - horizontalPad * 2, size.y - topHudReserve - 24)
        .clamp(260.0, 440.0)
        .toDouble();
    boardLayer
      ..size = Vector2(side, side)
      ..position = Vector2(
        (size.x - side) / 2,
        topHudReserve + (size.y - topHudReserve - side) / 2,
      );
  }

  void notifyHud() => hudRevision.value++;

  void maybeNotifyRoundEnded() {
    if (board.isTerminal || board.reachedTarget) {
      onRoundEnded?.call();
    }
  }
}

class TileSwapBoardComponent extends PositionComponent with DragCallbacks {
  TileSwapBoardComponent({required this.gameRef}) : super(priority: 1);

  final TileSwapGame gameRef;

  static const double _gap = 3;

  /// Legal swap then cascade
  static const double _swapSec = 0.22;

  /// Illegal swap: cross, then return (two halves).
  static const double _rejectHalfSec = 0.16;

  static const double _clearSec = 0.16;
  static const double _fallSec = 0.26;
  static const double _spawnSec = 0.24;
  static const double _particleLifeSec = 0.34;
  static const int _particlesPerCell = 7;
  static const int _maxParticles = 260;

  bool _busy = false;
  double _phaseElapsed = 0;

  /// Drag state (only while pointer down and not [_busy]).
  int? _dragFromR;
  int? _dragFromC;
  int _dragKind = 0;
  final Vector2 _dragFloatLocal = Vector2.zero();

  int? _swapR1;
  int? _swapC1;
  int? _swapR2;
  int? _swapC2;
  int _swapK1 = 0;
  int _swapK2 = 0;

  /// True: animate swap then revert (grid unchanged).
  bool _swapIsReject = false;

  Set<(int, int)>? _clearCells;
  Map<(int, int), int>? _clearKinds;

  List<TileGravityMove>? _fallMoves;

  List<TileSpawn>? _spawns;
  final List<_ClearParticle> _particles = <_ClearParticle>[];

  /// First clear after a normal swap uses swap cells as special pivot preference.
  int? _prefSwapR1;
  int? _prefSwapC1;
  int? _prefSwapR2;
  int? _prefSwapC2;

  /// Special activation / chain clears that must not spawn new specials from shape rules.
  bool _plainRemovalClear = false;

  void resetAnimationState() {
    _busy = false;
    _phaseElapsed = 0;
    _clearDrag();
    _swapR1 = _swapC1 = _swapR2 = _swapC2 = null;
    _swapIsReject = false;
    _clearCells = null;
    _clearKinds = null;
    _fallMoves = null;
    _spawns = null;
    _particles.clear();
    _prefSwapR1 = _prefSwapC1 = _prefSwapR2 = _prefSwapC2 = null;
    _plainRemovalClear = false;
  }

  void _clearDrag() {
    _dragFromR = _dragFromC = null;
  }

  bool get _acceptInput => !_busy;

  double get _cell {
    final n = gameRef.board.gridSize.toDouble();
    final side = size.x;
    return (side - _gap * (n + 1)) / n;
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;

  Rect _cellRect(int r, int c) {
    final cell = _cell;
    final left = _gap + c * (cell + _gap);
    final top = _gap + r * (cell + _gap);
    return Rect.fromLTWH(left, top, cell, cell);
  }

  Offset _cellCenter(int r, int c) => _cellRect(r, c).center;

  Set<(int, int)> _cellsOccupiedByFall() {
    final moves = _fallMoves;
    if (moves == null) return {};
    final out = <(int, int)>{};
    for (final m in moves) {
      out.add((m.fromRow, m.c));
      out.add((m.toRow, m.c));
    }
    return out;
  }

  Set<(int, int)> _spawnTargets() {
    final sp = _spawns;
    if (sp == null) return {};
    return {for (final s in sp) (s.r, s.c)};
  }

  (int, int)? _hitCell(Vector2 localPosition) {
    final n = gameRef.board.gridSize;
    final cell = _cell;
    if (cell <= 0) return null;
    final x = localPosition.x;
    final y = localPosition.y;
    if (x < _gap || y < _gap) return null;
    final c = ((x - _gap) / (cell + _gap)).floor();
    final r = ((y - _gap) / (cell + _gap)).floor();
    if (r < 0 || r >= n || c < 0 || c >= n) return null;
    return (r, c);
  }

  /// Adjacent cell best matching drag direction / release point.
  (int, int)? _swapPartner(int fr, int fc, Vector2 releaseLocal) {
    final n = gameRef.board.gridSize;
    final cell = _cell;
    final hit = _hitCell(releaseLocal);
    if (hit != null &&
        TileSwapBoardModel.adjacent(fr, fc, hit.$1, hit.$2) &&
        hit != (fr, fc)) {
      return hit;
    }

    final origin = Offset(_cellCenter(fr, fc).dx, _cellCenter(fr, fc).dy);
    final dx = releaseLocal.x - origin.dx;
    final dy = releaseLocal.y - origin.dy;
    if (max(dx.abs(), dy.abs()) < cell * 0.12) return null;

    late final int tr;
    late final int tc;
    if (dx.abs() >= dy.abs()) {
      tc = fc + (dx > 0 ? 1 : -1);
      tr = fr;
    } else {
      tr = fr + (dy > 0 ? 1 : -1);
      tc = fc;
    }
    if (tr < 0 || tr >= n || tc < 0 || tc >= n) return null;
    if (!TileSwapBoardModel.adjacent(fr, fc, tr, tc)) return null;
    return (tr, tc);
  }

  /// 0 = drag origin cell center, 1 = partner cell center along the swap axis.
  double _dragSwapAxisProgress(
    int fr,
    int fc,
    int tr,
    int tc,
    Vector2 floatLocal,
  ) {
    final homeA = _cellCenter(fr, fc);
    final homeB = _cellCenter(tr, tc);
    final dx = homeB.dx - homeA.dx;
    final dy = homeB.dy - homeA.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq < 1e-9) return 0;
    final px = floatLocal.x - homeA.dx;
    final py = floatLocal.y - homeA.dy;
    final t = (px * dx + py * dy) / lenSq;
    return t.clamp(0.0, 1.0);
  }

  void _beginLegalSwapAnimation(int r1, int c1, int r2, int c2) {
    final b = gameRef.board;
    _busy = true;
    _swapIsReject = false;
    _phaseElapsed = 0;
    _swapR1 = r1;
    _swapC1 = c1;
    _swapR2 = r2;
    _swapC2 = c2;
    _swapK1 = b.grid[r1][c1];
    _swapK2 = b.grid[r2][c2];
  }

  void _beginRejectSwapAnimation(int r1, int c1, int r2, int c2) {
    gameRef.onIllegalSwap?.call();
    final b = gameRef.board;
    _busy = true;
    _swapIsReject = true;
    _phaseElapsed = 0;
    _swapR1 = r1;
    _swapC1 = c1;
    _swapR2 = r2;
    _swapC2 = c2;
    _swapK1 = b.grid[r1][c1];
    _swapK2 = b.grid[r2][c2];
  }

  void _finishRejectSwap() {
    _swapR1 = _swapC1 = _swapR2 = _swapC2 = null;
    _swapIsReject = false;
    _busy = false;
    _phaseElapsed = 0;
    gameRef.notifyHud();
  }

  void _finishSwapAndStartCascade() {
    gameRef.onLegalSwapCommitted?.call();
    final r1 = _swapR1!;
    final c1 = _swapC1!;
    final r2 = _swapR2!;
    final c2 = _swapC2!;
    final b = gameRef.board;
    final k1 = b.grid[r1][c1];
    final k2 = b.grid[r2][c2];

    _swapR1 = _swapC1 = _swapR2 = _swapC2 = null;
    _swapIsReject = false;

    b.commitSwap(r1, c1, r2, c2);

    if (TileSwapBoardModel.isSpecialTile(k1) ||
        TileSwapBoardModel.isSpecialTile(k2)) {
      final clears = b.computeSpecialSwapClears(
        swappedR1: r1,
        swappedC1: c1,
        swappedR2: r2,
        swappedC2: c2,
        kindBeforeAtR1: k1,
        kindBeforeAtR2: k2,
      );
      _plainRemovalClear = true;
      _prefSwapR1 = _prefSwapC1 = _prefSwapR2 = _prefSwapC2 = null;
      _beginClearPhase(clears);
      return;
    }

    _prefSwapR1 = r1;
    _prefSwapC1 = c1;
    _prefSwapR2 = r2;
    _prefSwapC2 = c2;
    _plainRemovalClear = false;

    _phaseElapsed = 0;
    _startCascadeAfterSwap();
  }

  void _startCascadeAfterSwap() {
    final matched = gameRef.board.findMatchesLive();
    if (matched.isEmpty) {
      gameRef.notifyHud();
      final ended =
          gameRef.board.isTerminal || gameRef.board.reachedTarget;
      _busy = ended;
      gameRef.maybeNotifyRoundEnded();
      _prefSwapR1 = _prefSwapC1 = _prefSwapR2 = _prefSwapC2 = null;
      return;
    }
    _beginClearPhase(matched);
  }

  void _beginClearPhase(Set<(int, int)> cells) {
    gameRef.onMatchClear?.call();
    final b = gameRef.board;
    _emitClearParticles(cells, b);
    _clearCells = cells;
    _clearKinds = {
      for (final p in cells) p: b.grid[p.$1][p.$2],
    };
    _phaseElapsed = 0;
  }

  void _emitClearParticles(Set<(int, int)> cells, TileSwapBoardModel b) {
    if (cells.isEmpty) return;
    final rng = gameRef._random;
    for (final p in cells) {
      final kind = b.grid[p.$1][p.$2];
      if (kind < 0) continue;
      final center = _cellCenter(p.$1, p.$2);
      final color = TileSwapGame.colorForKind(kind);
      for (var i = 0; i < _particlesPerCell; i++) {
        final angle = rng.nextDouble() * pi * 2;
        final speed = 95 + rng.nextDouble() * 150;
        final vx = cos(angle) * speed;
        final vy = sin(angle) * speed - 35;
        final life = _particleLifeSec * (0.72 + rng.nextDouble() * 0.38);
        final radius = 1.8 + rng.nextDouble() * 2.2;
        _particles.add(
          _ClearParticle(
            x: center.dx,
            y: center.dy,
            vx: vx,
            vy: vy,
            life: life,
            lifeMax: life,
            radius: radius,
            color: color,
          ),
        );
      }
    }
    if (_particles.length > _maxParticles) {
      _particles.removeRange(0, _particles.length - _maxParticles);
    }
  }

  void _updateParticles(double dt) {
    if (_particles.isEmpty) return;
    const gravity = 340.0;
    var w = 0;
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        continue;
      }
      p.vy += gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      _particles[w++] = p;
    }
    if (w < _particles.length) {
      _particles.removeRange(w, _particles.length);
    }
  }

  void _finishClear() {
    final cells = _clearCells!;
    final b = gameRef.board;

    if (_plainRemovalClear) {
      b.removeMatchedCells(cells);
      _plainRemovalClear = false;
    } else if (_prefSwapR1 != null) {
      b.removeMatchedCellsMaybeCreateSpecial(
        cells,
        prefR1: _prefSwapR1,
        prefC1: _prefSwapC1,
        prefR2: _prefSwapR2,
        prefC2: _prefSwapC2,
      );
      _prefSwapR1 = _prefSwapC1 = _prefSwapR2 = _prefSwapC2 = null;
    } else {
      b.removeMatchedCellsMaybeCreateSpecial(cells);
    }

    _clearCells = null;
    _clearKinds = null;
    _phaseElapsed = 0;

    _fallMoves = gameRef.board.peekGravityMoves();
    if (_fallMoves!.isEmpty) {
      _finishFall();
    }
  }

  void _finishFall() {
    gameRef.board.applyGravity();
    _fallMoves = null;
    _phaseElapsed = 0;

    _spawns = gameRef.board.peekSpawns();
    if (_spawns!.isEmpty) {
      _finishSpawn();
    }
  }

  void _finishSpawn() {
    final sp = _spawns;
    if (sp != null && sp.isNotEmpty) {
      gameRef.board.applySpawns(sp);
    }
    _spawns = null;
    _phaseElapsed = 0;

    final next = gameRef.board.findMatchesLive();
    if (next.isEmpty) {
      gameRef.notifyHud();
      final ended =
          gameRef.board.isTerminal || gameRef.board.reachedTarget;
      _busy = ended;
      gameRef.maybeNotifyRoundEnded();
    } else {
      _beginClearPhase(next);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateParticles(dt);
    if (!_busy) return;

    _phaseElapsed += dt;

    final sr1 = _swapR1;
    if (sr1 != null) {
      if (_swapIsReject) {
        if (_phaseElapsed >= _rejectHalfSec * 2) {
          _finishRejectSwap();
        }
      } else {
        if (_phaseElapsed >= _swapSec) {
          _finishSwapAndStartCascade();
        }
      }
      return;
    }

    if (_clearCells != null && _clearKinds != null) {
      if (_phaseElapsed >= _clearSec) {
        _finishClear();
      }
      return;
    }

    final falls = _fallMoves;
    if (falls != null) {
      if (_phaseElapsed >= _fallSec) {
        _finishFall();
      }
      return;
    }

    final sp = _spawns;
    if (sp != null) {
      if (_phaseElapsed >= _spawnSec) {
        _finishSpawn();
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_acceptInput) return;
    final hit = _hitCell(event.localPosition);
    if (hit == null) return;
    final kind = gameRef.board.grid[hit.$1][hit.$2];
    if (kind < 0) return;
    _dragFromR = hit.$1;
    _dragFromC = hit.$2;
    _dragKind = kind;
    _dragFloatLocal.setFrom(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragFromR == null) return;
    final d = event.localDelta;
    if (_v2Finite(d)) {
      _dragFloatLocal.add(d);
    } else {
      _dragFloatLocal.setFrom(event.localEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final fr = _dragFromR;
    final fc = _dragFromC;
    if (fr == null || fc == null) return;

    final partner = _swapPartner(fr, fc, _dragFloatLocal);
    _clearDrag();

    if (partner == null) {
      return;
    }

    final tr = partner.$1;
    final tc = partner.$2;
    final b = gameRef.board;

    if (!TileSwapBoardModel.adjacent(fr, fc, tr, tc)) {
      return;
    }

    if (b.validateSwapCreatesMatch(fr, fc, tr, tc)) {
      HapticFeedback.lightImpact();
      _beginLegalSwapAnimation(fr, fc, tr, tc);
    } else {
      HapticFeedback.selectionClick();
      _beginRejectSwapAnimation(fr, fc, tr, tc);
    }
    gameRef.notifyHud();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _clearDrag();
  }

  void _paintTile(
    Canvas canvas, {
    required Offset center,
    required double cellSize,
    required int kind,
    double scale = 1,
    double alpha = 1,
  }) {
    if (kind < 0 || alpha <= 0.01) return;
    final side = cellSize * scale;
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellSize * 0.18 * scale),
    );
    final fill = TileSwapGame.colorForKind(kind).withValues(alpha: alpha);

    canvas.drawRRect(rr.deflate(1), Paint()..color = fill);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.5, cellSize * 0.08)
      ..color = Colors.black.withValues(alpha: 0.88 * alpha);
    canvas.drawRRect(rr.deflate(1), outline);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, cellSize * 0.04)
      ..color = Colors.white.withValues(alpha: 0.65 * alpha);
    canvas.drawRRect(rr.deflate(2.5), inner);

    if (TileSwapBoardModel.isSpecialTile(kind)) {
      _paintSpecialOverlay(canvas, center, side, kind, alpha);
    }
  }

  void _paintSpecialOverlay(
    Canvas canvas,
    Offset center,
    double side,
    int kind,
    double alpha,
  ) {
    final sub = TileSwapBoardModel.specialSubtype(kind);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, side * 0.09)
      ..color = Colors.white.withValues(alpha: 0.92 * alpha);

    if (sub == TileSwapBoardModel.specialSubtypeLineH) {
      for (final dy in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(center.dx - side * 0.38, center.dy + dy * side * 0.16),
          Offset(center.dx + side * 0.38, center.dy + dy * side * 0.16),
          stroke,
        );
      }
    } else if (sub == TileSwapBoardModel.specialSubtypeLineV) {
      for (final dx in [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(center.dx + dx * side * 0.16, center.dy - side * 0.38),
          Offset(center.dx + dx * side * 0.16, center.dy + side * 0.38),
          stroke,
        );
      }
    } else if (sub == TileSwapBoardModel.specialSubtypeBomb) {
      canvas.drawCircle(center, side * 0.28, stroke);
      canvas.drawCircle(center, side * 0.14, stroke);
    } else if (sub == TileSwapBoardModel.specialSubtypeColorBomb) {
      canvas.drawCircle(center, side * 0.34, stroke);
      final dot = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * alpha);
      canvas.drawCircle(center, side * 0.09, dot);
    }
  }

  double _rejectVisT() {
    final half = _rejectHalfSec;
    if (_phaseElapsed < half) {
      return _smoothStep(_phaseElapsed / half);
    }
    return _smoothStep(1 - (_phaseElapsed - half) / half);
  }

  @override
  void render(Canvas canvas) {
    final board = gameRef.board;
    final n = board.gridSize;
    final cell = _cell;
    if (cell <= 0) return;

    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      bg,
      Paint()..color = const Color(0xFF1E2635),
    );

    final fallingCells = _cellsOccupiedByFall();
    final spawningTo = _spawnTargets();

    double? swapT;
    if (_swapR1 != null && !_swapIsReject) {
      swapT = (_phaseElapsed / _swapSec).clamp(0.0, 1.0);
    }

    final rejectT = (_swapR1 != null && _swapIsReject) ? _rejectVisT() : null;

    final clearT = _clearCells != null
        ? (_phaseElapsed / _clearSec).clamp(0.0, 1.0)
        : null;

    final fallT = _fallMoves != null
        ? (_phaseElapsed / _fallSec).clamp(0.0, 1.0)
        : null;

    final spawnT = _spawns != null
        ? (_phaseElapsed / _spawnSec).clamp(0.0, 1.0)
        : null;

    final skipStatic = <(int, int)>{};
    if (swapT != null || rejectT != null) {
      skipStatic.add((_swapR1!, _swapC1!));
      skipStatic.add((_swapR2!, _swapC2!));
    }
    skipStatic.addAll(fallingCells);
    if (spawnT != null) {
      skipStatic.addAll(spawningTo);
    }

    final draggingFrom =
        _dragFromR != null && _acceptInput ? (_dragFromR!, _dragFromC!) : null;
    (int, int)? dragPartnerCell;
    var dragPartnerT = 0.0;
    if (draggingFrom != null) {
      skipStatic.add(draggingFrom);
      final fr = draggingFrom.$1;
      final fc = draggingFrom.$2;
      dragPartnerCell = _swapPartner(fr, fc, _dragFloatLocal);
      if (dragPartnerCell != null) {
        dragPartnerT = _dragSwapAxisProgress(
          fr,
          fc,
          dragPartnerCell.$1,
          dragPartnerCell.$2,
          _dragFloatLocal,
        );
        skipStatic.add(dragPartnerCell);
      }
    }

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = _cellRect(r, c);
        final rrBg = RRect.fromRectAndRadius(
          rect.deflate(1),
          Radius.circular(cell * 0.12),
        );
        canvas.drawRRect(
          rrBg,
          Paint()..color = const Color(0xFF151D2E),
        );

        if (skipStatic.contains((r, c))) continue;

        final kind = board.grid[r][c];
        if (kind < 0) continue;

        double scale = 1;
        double alpha = 1;

        if (clearT != null &&
            _clearCells != null &&
            _clearCells!.contains((r, c))) {
          final ck = _clearKinds![(r, c)];
          if (ck != null) {
            final u = _smoothStep(clearT);
            scale = 1 - u * 0.85;
            alpha = 1 - u;
            _paintTile(
              canvas,
              center: rect.center,
              cellSize: cell,
              kind: ck,
              scale: scale,
              alpha: alpha,
            );
          }
          continue;
        }

        _paintTile(
          canvas,
          center: rect.center,
          cellSize: cell,
          kind: kind,
        );
      }
    }

    // Legal swap overlay
    if (swapT != null) {
      final t = _smoothStep(swapT);
      final p1 = Offset.lerp(
        _cellCenter(_swapR1!, _swapC1!),
        _cellCenter(_swapR2!, _swapC2!),
        t,
      )!;
      final p2 = Offset.lerp(
        _cellCenter(_swapR2!, _swapC2!),
        _cellCenter(_swapR1!, _swapC1!),
        t,
      )!;
      _paintTile(canvas, center: p1, cellSize: cell, kind: _swapK1);
      _paintTile(canvas, center: p2, cellSize: cell, kind: _swapK2);
    }

    // Illegal swap: cross then uncross
    if (rejectT != null) {
      final t = rejectT;
      final p1 = Offset.lerp(
        _cellCenter(_swapR1!, _swapC1!),
        _cellCenter(_swapR2!, _swapC2!),
        t,
      )!;
      final p2 = Offset.lerp(
        _cellCenter(_swapR2!, _swapC2!),
        _cellCenter(_swapR1!, _swapC1!),
        t,
      )!;
      _paintTile(canvas, center: p1, cellSize: cell, kind: _swapK1);
      _paintTile(canvas, center: p2, cellSize: cell, kind: _swapK2);
    }

    if (fallT != null && _fallMoves != null) {
      final u = _smoothStep(fallT);
      for (final m in _fallMoves!) {
        final y = _lerp(
          _cellCenter(m.fromRow, m.c).dy,
          _cellCenter(m.toRow, m.c).dy,
          u,
        );
        final cx = Offset(_cellCenter(m.fromRow, m.c).dx, y);
        _paintTile(canvas, center: cx, cellSize: cell, kind: m.kind);
      }
    }

    if (spawnT != null && _spawns != null) {
      final u = _smoothStep(spawnT);
      for (final s in _spawns!) {
        final startY = _cellRect(0, s.c).top - cell * 1.1;
        final endY = _cellCenter(s.r, s.c).dy;
        final y = _lerp(startY, endY, u);
        final cx = Offset(_cellCenter(s.r, s.c).dx, y);
        final alpha = min(1.0, u * 1.15);
        _paintTile(
          canvas,
          center: cx,
          cellSize: cell,
          kind: s.kind,
          alpha: alpha,
        );
      }
    }

    if (_particles.isNotEmpty) {
      for (final p in _particles) {
        final t = (p.life / p.lifeMax).clamp(0.0, 1.0);
        final alpha = _smoothStep(t);
        final paint = Paint()
          ..color = p.color.withValues(alpha: 0.82 * alpha);
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.radius * (0.66 + 0.58 * alpha),
          paint,
        );
      }
    }

    // Partner tile travels toward the dragged tile's home (swap preview).
    if (draggingFrom != null && dragPartnerCell != null) {
      final fr = draggingFrom.$1;
      final fc = draggingFrom.$2;
      final tr = dragPartnerCell.$1;
      final tc = dragPartnerCell.$2;
      final pk = board.grid[tr][tc];
      if (pk >= 0) {
        final partnerCenter = Offset.lerp(
          _cellCenter(tr, tc),
          _cellCenter(fr, fc),
          dragPartnerT,
        )!;
        _paintTile(
          canvas,
          center: partnerCenter,
          cellSize: cell,
          kind: pk,
          scale: 1.05,
          alpha: 0.9,
        );
      }
    }

    // Floating drag ghost
    if (draggingFrom != null) {
      final o = Offset(_dragFloatLocal.x, _dragFloatLocal.y);
      _paintTile(
        canvas,
        center: o,
        cellSize: cell,
        kind: _dragKind,
        scale: 1.06,
        alpha: 0.92,
      );
    }
  }
}

class _ClearParticle {
  _ClearParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.lifeMax,
    required this.radius,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double lifeMax;
  final double radius;
  final Color color;
}
