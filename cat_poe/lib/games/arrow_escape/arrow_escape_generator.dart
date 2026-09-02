import 'dart:math';

import 'arrow_escape_engine.dart';
import 'arrow_escape_models.dart';
import 'arrow_escape_solver.dart';

enum _HamMode { rowSerpent, colSerpent, spiral, randomPick }

/// Full-cover boards (every cell belongs to exactly one arrow).
///
/// Validated constraints:
/// - Each arrow length in **[2, 20]** cells.
/// - At least **5** arrows per board.
/// - Among arrows with length **> 2**, at most **10%** may be straight (no turns);
///   enforced as `straightLong <= floor(longCount * 0.10)`.
/// - At most **10%** of arrows may have length **exactly 2** (≥90% are longer).
/// - Grid scales from **5×5** up to **25×12** (rows × cols).
///
/// Generation rotates several **Hamiltonian walks** (serpent variants, spirals),
/// **earthworm** growth, **weighted** arrow-length mixes, and random **mirrors** so
/// puzzles stay visually fresh between rounds.
class ArrowEscapeGenerator {
  ArrowEscapeGenerator._();

  static const int _minRows = 5;
  static const int _maxRows = 25;
  static const int _minCols = 5;
  static const int _maxCols = 12;

  static const int _minCells = 2;
  static const int _maxCells = 20;
  static const int _minArrowsPerBoard = 5;

  static const double _maxStraightFractionForLongArrows = 0.10;

  /// Max fraction of arrows that may have length exactly [_minCells] (2).
  static const double _maxFractionLength2Arrows = 0.10;

  static ArrowEscapeEngine generate(
    Random rng, {
    int maxLives = 3,
    int difficultyLevel = 0,
  }) {
    ArrowEscapeSolver.clearMemo();
    final rows =
        (_minRows + difficultyLevel ~/ 2).clamp(_minRows, _maxRows).toInt();
    final cols =
        (_minCols + difficultyLevel ~/ 2).clamp(_minCols, _maxCols).toInt();

    ArrowEscapeEngine? tryReturn(ArrowEscapeLevelDef level) {
      final decorated = _decorateSymmetry(rng, rows, cols, level);
      if (!_validateBoardConstraints(decorated)) return null;
      try {
        final eng = ArrowEscapeEngine.fromLevel(decorated, maxLives: maxLives);
        if (_isValidStartState(eng)) return eng;
      } catch (_) {}
      return null;
    }

    final builders = <ArrowEscapeLevelDef? Function()>[
      () => _tryBuildEarthworm(rng, rows, cols, biasTurns: false),
      () => _tryBuildEarthworm(rng, rows, cols, biasTurns: true),
      () => _tryHamiltonianPartition(rng, rows, cols, mode: _HamMode.rowSerpent),
      () => _tryHamiltonianPartition(rng, rows, cols, mode: _HamMode.colSerpent),
      () => _tryHamiltonianPartition(rng, rows, cols, mode: _HamMode.spiral),
      () => _tryHamiltonianPartition(rng, rows, cols, mode: _HamMode.randomPick),
    ]..shuffle(rng);

    const attemptsPerStrategy = 40;
    for (var round = 0; round < attemptsPerStrategy; round++) {
      for (final make in builders) {
        final level = make();
        final eng = level == null ? null : tryReturn(level);
        if (eng != null) return eng;
      }
    }

    // Guaranteed retries — partitioned Hamiltonian snake always tiles the grid.
    for (var k = 0; k < 120; k++) {
      final level = _buildEmergencyPartitionedSnake(rng, rows, cols);
      final eng = tryReturn(level);
      if (eng != null) return eng;
    }

    // Exhaustive retry with deterministic seeds (should succeed in practice).
    for (var seed = 0; seed < 2000; seed++) {
      final r = Random(seed);
      final level = _tryHamiltonianPartition(
            r,
            rows,
            cols,
            mode: _HamMode.randomPick,
          ) ??
          _tryBuildEarthworm(r, rows, cols, biasTurns: seed.isOdd) ??
          _buildEmergencyPartitionedSnake(r, rows, cols);
      final eng = tryReturn(level);
      if (eng != null) return eng;
    }

    // Final passes — broader snake partitions (constraints + solvability checked).
    for (var seed = 2000; seed < 25000; seed++) {
      final r = Random(seed);
      final level =
          _buildEmergencyPartitionedSnake(r, rows, cols);
      final eng = tryReturn(level);
      if (eng != null) return eng;
    }

    throw StateError(
      'ArrowEscapeGenerator: could not satisfy constraints for ${rows}x$cols',
    );
  }

  static bool _isValidStartState(ArrowEscapeEngine eng) {
    if (!ArrowEscapeSolver.isSolvable(eng)) return false;
    for (var i = 0; i < eng.paths.length; i++) {
      if (eng.isRemoved(i)) continue;
      if (eng.canEscapeArrow(i)) return true;
    }
    return false;
  }

  static bool _validateArrowLengths(ArrowEscapeLevelDef level) {
    for (final p in level.paths) {
      final len = p.cells.length;
      if (len < _minCells || len > _maxCells) return false;
    }
    return true;
  }

  static bool _hasMinArrowCount(ArrowEscapeLevelDef level) =>
      level.paths.length >= _minArrowsPerBoard;

  static bool _isTwisted(List<(int, int)> cells) {
    if (cells.length <= 2) return false;
    for (var i = 2; i < cells.length; i++) {
      final a = cells[i - 2];
      final b = cells[i - 1];
      final c = cells[i];
      final d1 = (b.$1 - a.$1, b.$2 - a.$2);
      final d2 = (c.$1 - b.$1, c.$2 - b.$2);
      if (d1 != d2) return true;
    }
    return false;
  }

  /// At most `floor(n * 10%)` arrows may be exactly two cells long.
  static bool _meetsShortArrowQuota(ArrowEscapeLevelDef level) {
    final n = level.paths.length;
    if (n == 0) return false;
    final len2 = level.paths.where((p) => p.cells.length == 2).length;
    final maxLen2 = (n * _maxFractionLength2Arrows).floor();
    return len2 <= maxLen2;
  }

  static bool _meetsTwistQuota(ArrowEscapeLevelDef level) {
    var longCount = 0;
    var straightLongCount = 0;
    for (final p in level.paths) {
      if (p.cells.length <= 2) continue;
      longCount++;
      if (!_isTwisted(p.cells)) straightLongCount++;
    }
    if (longCount == 0) return true;
    final maxStraightAllowed =
        (longCount * _maxStraightFractionForLongArrows).floor();
    return straightLongCount <= maxStraightAllowed;
  }

  static bool _validateBoardConstraints(ArrowEscapeLevelDef level) {
    if (!_validateArrowLengths(level)) return false;
    if (!_hasMinArrowCount(level)) return false;
    if (!_meetsShortArrowQuota(level)) return false;
    if (!_meetsTwistQuota(level)) return false;
    return true;
  }

  /// Random horizontal / vertical mirror so similar generators still look different.
  static ArrowEscapeLevelDef _decorateSymmetry(
    Random rng,
    int rows,
    int cols,
    ArrowEscapeLevelDef level,
  ) {
    var l = level;
    if (rng.nextBool()) {
      l = _mirrorCols(l, cols);
    }
    if (rng.nextBool()) {
      l = _mirrorRows(l, rows);
    }
    return l;
  }

  static ArrowEscapeLevelDef _mirrorCols(ArrowEscapeLevelDef level, int cols) {
    final cM = cols - 1;
    return ArrowEscapeLevelDef(
      rows: level.rows,
      cols: level.cols,
      name: level.name == null ? null : '${level.name}_mcol',
      paths: [
        for (final p in level.paths)
          ArrowPathDef(
            cells: [for (final x in p.cells) (x.$1, cM - x.$2)],
            headDir: arrowEscapeDirBetween(
              (
                p.cells[p.cells.length - 2].$1,
                cM - p.cells[p.cells.length - 2].$2,
              ),
              (p.cells.last.$1, cM - p.cells.last.$2),
            )!,
          ),
      ],
    );
  }

  static ArrowEscapeLevelDef _mirrorRows(ArrowEscapeLevelDef level, int rows) {
    final rM = rows - 1;
    return ArrowEscapeLevelDef(
      rows: level.rows,
      cols: level.cols,
      name: level.name == null ? null : '${level.name}_mrow',
      paths: [
        for (final p in level.paths)
          ArrowPathDef(
            cells: [for (final x in p.cells) (rM - x.$1, x.$2)],
            headDir: arrowEscapeDirBetween(
              (
                rM - p.cells[p.cells.length - 2].$1,
                p.cells[p.cells.length - 2].$2,
              ),
              (rM - p.cells.last.$1, p.cells.last.$2),
            )!,
          ),
      ],
    );
  }

  static List<(int, int)> _pickHamiltonianWalk(Random rng, int rows, int cols) {
    switch (rng.nextInt(6)) {
      case 0:
        return _buildSpiralSerpent(rows, cols, clockwise: rng.nextBool());
      case 1:
        return _buildRowSerpentVariety(rows, cols, rng);
      case 2:
        return _buildColSerpentVariety(rows, cols, rng);
      case 3:
        return _buildRowSerpent(rows, cols);
      case 4:
        return _buildColSerpent(rows, cols);
      default:
        return rng.nextBool()
            ? _buildRowSerpentVariety(rows, cols, rng)
            : _buildColSerpentVariety(rows, cols, rng);
    }
  }

  /// Partition a full grid walk into arrows (serpent / spiral / variants).
  static ArrowEscapeLevelDef? _tryHamiltonianPartition(
    Random rng,
    int rows,
    int cols, {
    required _HamMode mode,
  }) {
    const modes = [_HamMode.rowSerpent, _HamMode.colSerpent, _HamMode.spiral];
    final effective =
        mode == _HamMode.randomPick ? modes[rng.nextInt(modes.length)] : mode;

    final walk = switch (effective) {
      _HamMode.rowSerpent => _buildRowSerpentVariety(rows, cols, rng),
      _HamMode.colSerpent => _buildColSerpentVariety(rows, cols, rng),
      _HamMode.spiral =>
        _buildSpiralSerpent(rows, cols, clockwise: rng.nextBool()),
      _HamMode.randomPick => _buildRowSerpentVariety(rows, cols, rng),
    };

    final ordered =
        rng.nextBool() ? walk.reversed.toList() : List<(int, int)>.from(walk);
    final segCount = _randomFeasibleSegmentCount(rng, ordered.length);
    if (segCount == null) return null;

    final paths = rng.nextDouble() < 0.52
        ? _partitionOrderedWeighted(rng, ordered, segCount)
        : _partitionOrderedIntoArrowDefs(rng, ordered, segCount);
    if (paths == null) return null;

    final tag = switch (effective) {
      _HamMode.rowSerpent => 'ham_row',
      _HamMode.colSerpent => 'ham_col',
      _HamMode.spiral => 'ham_spiral',
      _HamMode.randomPick => 'ham_pick',
    };

    return ArrowEscapeLevelDef(
      rows: rows,
      cols: cols,
      paths: paths,
      name: tag,
    );
  }

  /// Outer-ring spiral covering every cell once (classic peel walk).
  static List<(int, int)> _buildSpiralSerpent(
    int rows,
    int cols, {
    required bool clockwise,
  }) {
    final out = <(int, int)>[];
    var top = 0;
    var bottom = rows - 1;
    var left = 0;
    var right = cols - 1;

    while (top <= bottom && left <= right) {
      if (clockwise) {
        for (var c = left; c <= right; c++) {
          out.add((top, c));
        }
        top++;
        if (top > bottom) break;
        for (var r = top; r <= bottom; r++) {
          out.add((r, right));
        }
        right--;
        if (left > right) break;
        for (var c = right; c >= left; c--) {
          out.add((bottom, c));
        }
        bottom--;
        if (top > bottom) break;
        for (var r = bottom; r >= top; r--) {
          out.add((r, left));
        }
        left++;
      } else {
        for (var r = top; r <= bottom; r++) {
          out.add((r, left));
        }
        left++;
        if (left > right) break;
        for (var c = left; c <= right; c++) {
          out.add((bottom, c));
        }
        bottom--;
        if (top > bottom) break;
        for (var r = bottom; r >= top; r--) {
          out.add((r, right));
        }
        right--;
        if (left > right) break;
        for (var c = right; c >= left; c--) {
          out.add((top, c));
        }
        top++;
      }
    }
    return out;
  }

  /// Row-wise serpent with swapped zig-zag phase and/or vertical reversal.
  static List<(int, int)> _buildRowSerpentVariety(
    int rows,
    int cols,
    Random rng,
  ) {
    final reverseRows = rng.nextBool();
    final swapParity = rng.nextBool();
    final snake = <(int, int)>[];
    for (var k = 0; k < rows; k++) {
      final r = reverseRows ? rows - 1 - k : k;
      final forward = swapParity ? k.isOdd : k.isEven;
      if (forward) {
        for (var c = 0; c < cols; c++) {
          snake.add((r, c));
        }
      } else {
        for (var c = cols - 1; c >= 0; c--) {
          snake.add((r, c));
        }
      }
    }
    return snake;
  }

  /// Column-wise serpent with swapped zig-zag phase and/or horizontal reversal.
  static List<(int, int)> _buildColSerpentVariety(
    int rows,
    int cols,
    Random rng,
  ) {
    final reverseCols = rng.nextBool();
    final swapParity = rng.nextBool();
    final snake = <(int, int)>[];
    for (var k = 0; k < cols; k++) {
      final c = reverseCols ? cols - 1 - k : k;
      final forward = swapParity ? k.isOdd : k.isEven;
      if (forward) {
        for (var r = 0; r < rows; r++) {
          snake.add((r, c));
        }
      } else {
        for (var r = rows - 1; r >= 0; r--) {
          snake.add((r, c));
        }
      }
    }
    return snake;
  }

  /// Like [_partitionOrderedIntoArrowDefs] but biases slack toward uneven lengths.
  static List<ArrowPathDef>? _partitionOrderedWeighted(
    Random rng,
    List<(int, int)> ordered,
    int segmentCount,
  ) {
    final n = ordered.length;
    if (segmentCount * _maxCells < n || segmentCount * _minCells > n) {
      return null;
    }

    final lengths = List<int>.filled(segmentCount, _minCells);
    var slack = n - segmentCount * _minCells;
    var guard = 0;
    while (slack > 0 && guard < 100000) {
      guard++;
      final bias = pow(rng.nextDouble(), 0.42 + rng.nextDouble() * 0.38);
      var idx = (bias * segmentCount).floor();
      if (idx >= segmentCount) {
        idx = segmentCount - 1;
      }
      if (lengths[idx] >= _maxCells) continue;
      lengths[idx]++;
      slack--;
    }
    if (slack != 0) return null;

    final paths = <ArrowPathDef>[];
    var offset = 0;
    for (final len in lengths) {
      final segment = ordered.sublist(offset, offset + len);
      offset += len;
      final prev = segment[segment.length - 2];
      final head = segment.last;
      final dir = arrowEscapeDirBetween(prev, head);
      if (dir == null) return null;
      paths.add(ArrowPathDef(cells: segment, headDir: dir));
    }
    return paths;
  }

  /// Feasible segment counts k with `k * minLen <= n <= k * maxLen` and `k >= minArrows`.
  static int? _randomFeasibleSegmentCount(Random rng, int n) {
    final minByCover = (n + _maxCells - 1) ~/ _maxCells;
    final maxByCover = n ~/ _minCells;
    final lo = max(_minArrowsPerBoard, minByCover);
    final hi = maxByCover;
    if (lo > hi) return null;
    return lo + rng.nextInt(hi - lo + 1);
  }

  /// Partition [ordered] into [segmentCount] contiguous stretches, each in [2,20].
  static List<ArrowPathDef>? _partitionOrderedIntoArrowDefs(
    Random rng,
    List<(int, int)> ordered,
    int segmentCount,
  ) {
    final n = ordered.length;
    if (segmentCount * _maxCells < n || segmentCount * _minCells > n) {
      return null;
    }

    final lengths = List<int>.filled(segmentCount, _minCells);
    var slack = n - segmentCount * _minCells;
    var guard = 0;
    while (slack > 0 && guard < 100000) {
      guard++;
      final idx = rng.nextInt(segmentCount);
      if (lengths[idx] >= _maxCells) continue;
      lengths[idx]++;
      slack--;
    }
    if (slack != 0) return null;

    final paths = <ArrowPathDef>[];
    var offset = 0;
    for (final len in lengths) {
      final segment = ordered.sublist(offset, offset + len);
      offset += len;
      final prev = segment[segment.length - 2];
      final head = segment.last;
      final dir = arrowEscapeDirBetween(prev, head);
      if (dir == null) return null;
      paths.add(ArrowPathDef(cells: segment, headDir: dir));
    }
    return paths;
  }

  static List<(int, int)> _buildRowSerpent(int rows, int cols) {
    final snake = <(int, int)>[];
    for (var r = 0; r < rows; r++) {
      if (r.isEven) {
        for (var c = 0; c < cols; c++) {
          snake.add((r, c));
        }
      } else {
        for (var c = cols - 1; c >= 0; c--) {
          snake.add((r, c));
        }
      }
    }
    return snake;
  }

  static List<(int, int)> _buildColSerpent(int rows, int cols) {
    final snake = <(int, int)>[];
    for (var c = 0; c < cols; c++) {
      if (c.isEven) {
        for (var r = 0; r < rows; r++) {
          snake.add((r, c));
        }
      } else {
        for (var r = rows - 1; r >= 0; r--) {
          snake.add((r, c));
        }
      }
    }
    return snake;
  }

  /// Bias toward length ≥ 3 so boards usually satisfy the “≤10% length‑2 arrows” rule.
  static int _pickWormTargetLength(Random rng) {
    if (rng.nextDouble() < _maxFractionLength2Arrows) {
      return _minCells;
    }
    return 3 + rng.nextInt(_maxCells - 2);
  }

  /// **Earthworm**: grow random orthogonal paths; optional bias toward turning.
  static ArrowEscapeLevelDef? _tryBuildEarthworm(
    Random rng,
    int rows,
    int cols, {
    required bool biasTurns,
  }) {
    final unassigned = <(int, int)>{
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) (r, c),
    };
    final paths = <ArrowPathDef>[];

    const deltas = <(int, int)>[(0, 1), (0, -1), (1, 0), (-1, 0)];

    List<(int, int)> neigh((int, int) cell) {
      final out = <(int, int)>[];
      for (final d in deltas) {
        final nr = cell.$1 + d.$1;
        final nc = cell.$2 + d.$2;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        final n = (nr, nc);
        if (unassigned.contains(n)) out.add(n);
      }
      return out;
    }

    bool hasSingletonPocket() {
      for (final cell in unassigned) {
        var count = 0;
        for (final d in deltas) {
          final nr = cell.$1 + d.$1;
          final nc = cell.$2 + d.$2;
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          if (unassigned.contains((nr, nc))) count++;
        }
        if (count == 0) return true;
      }
      return false;
    }

    (int, int)? pickNext((int, int) tail, (int, int)? prev) {
      final candidates = neigh(tail);
      if (candidates.isEmpty) return null;
      if (!biasTurns || prev == null || candidates.length == 1) {
        return candidates[rng.nextInt(candidates.length)];
      }
      final pr = prev.$1;
      final pc = prev.$2;
      final tr = tail.$1;
      final tc = tail.$2;
      final straight = (2 * tr - pr, 2 * tc - pc);
      final turns =
          candidates.where((x) => x != straight).toList(growable: false);
      if (turns.isNotEmpty && rng.nextDouble() < 0.72) {
        return turns[rng.nextInt(turns.length)];
      }
      return candidates[rng.nextInt(candidates.length)];
    }

    while (unassigned.isNotEmpty) {
      final seed = unassigned.elementAt(rng.nextInt(unassigned.length));
      final pathRev = <(int, int)>[seed];
      unassigned.remove(seed);

      final targetLen = _pickWormTargetLength(rng);

      while (pathRev.length < targetLen) {
        final tail = pathRev.first;
        final prev = pathRev.length >= 2 ? pathRev[1] : null;
        final next = pickNext(tail, prev);
        if (next == null) break;
        pathRev.insert(0, next);
        unassigned.remove(next);
      }

      if (pathRev.length < _minCells || pathRev.length > _maxCells) {
        return null;
      }

      if (hasSingletonPocket()) return null;

      final forward = rng.nextBool();
      final ordered = forward ? pathRev.reversed.toList() : pathRev;
      final prev = ordered[ordered.length - 2];
      final head = ordered.last;
      final dir = arrowEscapeDirBetween(prev, head);
      if (dir == null) return null;

      paths.add(ArrowPathDef(cells: ordered, headDir: dir));
    }

    return ArrowEscapeLevelDef(
      rows: rows,
      cols: cols,
      paths: paths,
      name: biasTurns ? 'earthworm_turny' : 'earthworm',
    );
  }

  static List<int>? _balancedSegmentLengths(int totalCells, int segmentCount) {
    if (segmentCount * _maxCells < totalCells ||
        segmentCount * _minCells > totalCells) {
      return null;
    }
    final lengths = List<int>.filled(segmentCount, _minCells);
    var slack = totalCells - segmentCount * _minCells;
    var i = 0;
    while (slack > 0) {
      final idx = i % segmentCount;
      if (lengths[idx] >= _maxCells) {
        return null;
      }
      lengths[idx]++;
      slack--;
      i++;
      if (i > segmentCount * _maxCells * 50) {
        return null;
      }
    }
    return lengths;
  }

  static List<ArrowPathDef>? _pathsFromLengths(
    List<(int, int)> ordered,
    List<int> lengths,
  ) {
    var offset = 0;
    final paths = <ArrowPathDef>[];
    for (final len in lengths) {
      final segment = ordered.sublist(offset, offset + len);
      offset += len;
      if (segment.length < 2) {
        return null;
      }
      final prev = segment[segment.length - 2];
      final head = segment.last;
      final dir = arrowEscapeDirBetween(prev, head);
      if (dir == null) {
        return null;
      }
      paths.add(ArrowPathDef(cells: segment, headDir: dir));
    }
    if (offset != ordered.length) {
      return null;
    }
    return paths;
  }

  static ArrowEscapeLevelDef _buildEmergencyPartitionedSnake(
    Random rng,
    int rows,
    int cols,
  ) {
    final walk = _pickHamiltonianWalk(rng, rows, cols);
    final ordered =
        rng.nextBool() ? walk.reversed.toList() : List<(int, int)>.from(walk);

    for (var seed = 0; seed < 25000; seed++) {
      final r = Random(seed ^ rows ^ cols);
      final segCount = _randomFeasibleSegmentCount(r, ordered.length);
      if (segCount == null) {
        continue;
      }
      final paths = r.nextDouble() < 0.5
          ? _partitionOrderedWeighted(r, ordered, segCount)
          : _partitionOrderedIntoArrowDefs(r, ordered, segCount);
      if (paths == null) {
        continue;
      }
      final level = ArrowEscapeLevelDef(
        rows: rows,
        cols: cols,
        paths: paths,
        name: 'emergency_snake',
      );
      if (_validateBoardConstraints(level)) {
        return level;
      }
    }

    final lo = max(
      _minArrowsPerBoard,
      (ordered.length + _maxCells - 1) ~/ _maxCells,
    );
    final hi = ordered.length ~/ _minCells;
    for (var k = lo; k <= hi; k++) {
      final lengths = _balancedSegmentLengths(ordered.length, k);
      if (lengths == null) {
        continue;
      }
      final paths = _pathsFromLengths(ordered, lengths);
      if (paths == null) {
        continue;
      }
      final level = ArrowEscapeLevelDef(
        rows: rows,
        cols: cols,
        paths: paths,
        name: 'emergency_snake_balanced',
      );
      if (_validateBoardConstraints(level)) {
        return level;
      }
    }

    throw StateError(
      'ArrowEscapeGenerator: emergency snake failed for ${rows}x$cols',
    );
  }
}

