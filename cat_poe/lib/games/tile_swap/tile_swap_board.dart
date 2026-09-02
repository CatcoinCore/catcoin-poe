import 'dart:math';

/// One tile falling vertically within a column after clears.
typedef TileGravityMove = ({
  int c,
  int fromRow,
  int toRow,
  int kind,
});

/// New tile spawning into an empty cell (after gravity).
typedef TileSpawn = ({int r, int c, int kind});

/// Normal tiles use `0 .. tileKinds-1`. [holeTile] during cascades. Special tiles
/// use encoded kinds ≥ [specialTileMin] (striped row/col, 3×3 burst, color burst).
class TileSwapBoardModel {
  TileSwapBoardModel({
    required this.gridSize,
    required this.tileKinds,
    required this.movesRemaining,
    required this.targetScore,
    required this.pointsPerTile,
    required this.grid,
    required this.random,
  });

  static const int holeTile = -1;

  /// Encoded as `specialTileMin + baseColor * specialStride + subtype`.
  static const int specialTileMin = 500;
  static const int specialStride = 10;

  /// Clears its row on swap activation.
  static const int specialSubtypeLineH = 0;

  /// Clears its column on swap activation.
  static const int specialSubtypeLineV = 1;

  /// Clears 8 neighbors (Moore) around itself on activation.
  static const int specialSubtypeBomb = 2;

  /// Clears all tiles matching swap partner color on activation.
  static const int specialSubtypeColorBomb = 3;

  final int gridSize;
  final int tileKinds;
  final Random random;

  int movesRemaining;
  int score = 0;
  final int targetScore;
  final int pointsPerTile;

  /// Tile kind: normal `0..tileKinds-1`, special ≥ [specialTileMin], [holeTile].
  final List<List<int>> grid;

  factory TileSwapBoardModel.newGame(
    Random rng, {
    int gridSize = 8,
    int tileKinds = 6,
    int moves = 22,
    int targetScore = 800,
    int pointsPerTile = 12,
  }) {
    final g = List.generate(
      gridSize,
      (_) => List<int>.filled(gridSize, 0),
    );
    final m = TileSwapBoardModel(
      gridSize: gridSize,
      tileKinds: tileKinds,
      movesRemaining: moves,
      targetScore: targetScore,
      pointsPerTile: pointsPerTile,
      grid: g,
      random: rng,
    );
    m._randomFillNoMatches();
    return m;
  }

  bool get isTerminal => movesRemaining <= 0;

  bool get reachedTarget => score >= targetScore;

  static bool adjacent(int r1, int c1, int r2, int c2) {
    final dr = (r1 - r2).abs();
    final dc = (c1 - c2).abs();
    return dr + dc == 1;
  }

  static bool isSpecialTile(int k) => k >= specialTileMin;

  static int tileMatchColor(int k) {
    if (k == holeTile) return holeTile;
    if (!isSpecialTile(k)) return k;
    return (k - specialTileMin) ~/ specialStride;
  }

  static int specialSubtype(int k) {
    if (!isSpecialTile(k)) return holeTile;
    return (k - specialTileMin) % specialStride;
  }

  static int encodeSpecial({required int baseColor, required int subtype}) =>
      specialTileMin + baseColor * specialStride + subtype;

  /// Swap allowed if it creates a match or moves a special tile.
  bool swapCreatesMatchOrUsesSpecial(int r1, int c1, int r2, int c2) {
    if (isTerminal) return false;
    if (!adjacent(r1, c1, r2, c2)) return false;
    final a = grid[r1][c1];
    final b = grid[r2][c2];
    if (isSpecialTile(a) || isSpecialTile(b)) return true;
    final trial = _cloneGrid();
    _swapCells(trial, r1, c1, r2, c2);
    return _findMatches(trial).isNotEmpty;
  }

  /// Legacy name kept for call sites; prefer [swapCreatesMatchOrUsesSpecial].
  bool validateSwapCreatesMatch(int r1, int c1, int r2, int c2) =>
      swapCreatesMatchOrUsesSpecial(r1, c1, r2, c2);

  /// Applies swap and consumes a move (call after swap animation). Does not resolve matches.
  void commitSwap(int r1, int c1, int r2, int c2) {
    _swapCells(grid, r1, c1, r2, c2);
    movesRemaining--;
  }

  /// Match set on the live grid (normals + specials match by base color).
  Set<(int, int)> findMatchesLive() => _findMatches(grid);

  /// Plain clear — cascades from specials or chain reactions without forming specials here.
  void removeMatchedCells(Set<(int, int)> matched) {
    if (matched.isEmpty) return;
    score += matched.length * pointsPerTile;
    for (final p in matched) {
      grid[p.$1][p.$2] = holeTile;
    }
  }

  /// Clears matches and may leave one [specialTileMin]+ tile at a pivot (4 / 5 / L rules).
  void removeMatchedCellsMaybeCreateSpecial(
    Set<(int, int)> matched, {
    int? prefR1,
    int? prefC1,
    int? prefR2,
    int? prefC2,
  }) {
    if (matched.isEmpty) return;
    final outcome = _classifyMatchOutcome(
      matched,
      prefR1: prefR1,
      prefC1: prefC1,
      prefR2: prefR2,
      prefC2: prefC2,
    );
    score += matched.length * pointsPerTile;
    for (final p in matched) {
      if (outcome.pivot != null &&
          outcome.specialKind != null &&
          p == outcome.pivot) {
        continue;
      }
      grid[p.$1][p.$2] = holeTile;
    }
    if (outcome.pivot != null && outcome.specialKind != null) {
      grid[outcome.pivot!.$1][outcome.pivot!.$2] = outcome.specialKind!;
    }
  }

  /// Cells cleared when swapping specials / special+normal after [commitSwap].
  /// Pass kinds **before** the swap at `(r1,c1)` and `(r2,c2)`.
  Set<(int, int)> computeSpecialSwapClears({
    required int swappedR1,
    required int swappedC1,
    required int swappedR2,
    required int swappedC2,
    required int kindBeforeAtR1,
    required int kindBeforeAtR2,
  }) {
    final out = <(int, int)>{};
    final k1 = kindBeforeAtR1;
    final k2 = kindBeforeAtR2;

    int? partnerIfSingleSpecial;
    if (isSpecialTile(k1) && !isSpecialTile(k2)) {
      partnerIfSingleSpecial = tileMatchColor(k2);
    } else if (!isSpecialTile(k1) && isSpecialTile(k2)) {
      partnerIfSingleSpecial = tileMatchColor(k1);
    }

    void addEffect(int afterR, int afterC, int kind, int? partner) {
      out.addAll(_expandSpecialAt(afterR, afterC, kind, partner));
    }

    if (isSpecialTile(k1)) {
      final p = isSpecialTile(k2) ? tileMatchColor(k2) : partnerIfSingleSpecial;
      addEffect(swappedR2, swappedC2, k1, p);
    }
    if (isSpecialTile(k2)) {
      final p = isSpecialTile(k1) ? tileMatchColor(k1) : partnerIfSingleSpecial;
      addEffect(swappedR1, swappedC1, k2, p);
    }

    return out;
  }

  /// Moves to apply after holes exist; does not mutate the grid.
  List<TileGravityMove> peekGravityMoves() {
    final n = gridSize;
    final moves = <TileGravityMove>[];
    for (var c = 0; c < n; c++) {
      final stack = <({int row, int kind})>[];
      for (var r = n - 1; r >= 0; r--) {
        final v = grid[r][c];
        if (v >= 0) {
          stack.add((row: r, kind: v));
        }
      }
      for (var i = 0; i < stack.length; i++) {
        final toRow = n - 1 - i;
        final fromRow = stack[i].row;
        final kind = stack[i].kind;
        if (fromRow != toRow) {
          moves.add(
            (c: c, fromRow: fromRow, toRow: toRow, kind: kind),
          );
        }
      }
    }
    return moves;
  }

  /// Random fills for current `-1` cells (top-left order); caller animates then applies via [applySpawns].
  List<TileSpawn> peekSpawns() {
    final n = gridSize;
    final out = <TileSpawn>[];
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (grid[r][c] < 0) {
          out.add((r: r, c: c, kind: random.nextInt(tileKinds)));
        }
      }
    }
    return out;
  }

  void applySpawns(List<TileSpawn> spawns) {
    for (final s in spawns) {
      grid[s.r][s.c] = s.kind;
    }
  }

  /// Sync grid after fall animation (compact columns).
  void applyGravity() {
    _applyGravity();
  }

  /// One-shot resolve without animation (e.g. tests).
  bool swapIfCreatesMatch(int r1, int c1, int r2, int c2) {
    if (!swapCreatesMatchOrUsesSpecial(r1, c1, r2, c2)) return false;
    commitSwap(r1, c1, r2, c2);
    _resolveAllMatches();
    return true;
  }

  void _randomFillNoMatches() {
    final n = gridSize;
    const maxAttempts = 400;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          grid[r][c] = random.nextInt(tileKinds);
        }
      }
      if (_findMatches(grid).isEmpty) return;
    }
  }

  List<List<int>> _cloneGrid() =>
      [for (final row in grid) List<int>.from(row)];

  void _swapCells(List<List<int>> g, int r1, int c1, int r2, int c2) {
    final t = g[r1][c1];
    g[r1][c1] = g[r2][c2];
    g[r2][c2] = t;
  }

  bool _alive(int v) => v >= 0;

  List<({int r, int c0, int len})> _horizontalRuns(List<List<int>> g) {
    final n = gridSize;
    final out = <({int r, int c0, int len})>[];
    for (var r = 0; r < n; r++) {
      var c = 0;
      while (c < n) {
        if (!_alive(g[r][c])) {
          c++;
          continue;
        }
        final mc = tileMatchColor(g[r][c]);
        var len = 1;
        while (c + len < n &&
            _alive(g[r][c + len]) &&
            tileMatchColor(g[r][c + len]) == mc) {
          len++;
        }
        if (len >= 3) {
          out.add((r: r, c0: c, len: len));
        }
        c += len;
      }
    }
    return out;
  }

  List<({int c, int r0, int len})> _verticalRunsOn(List<List<int>> g) {
    final n = gridSize;
    final out = <({int c, int r0, int len})>[];
    for (var c = 0; c < n; c++) {
      var r = 0;
      while (r < n) {
        if (!_alive(g[r][c])) {
          r++;
          continue;
        }
        final mc = tileMatchColor(g[r][c]);
        var len = 1;
        while (r + len < n &&
            _alive(g[r + len][c]) &&
            tileMatchColor(g[r + len][c]) == mc) {
          len++;
        }
        if (len >= 3) {
          out.add((c: c, r0: r, len: len));
        }
        r += len;
      }
    }
    return out;
  }

  Set<(int, int)> _findMatches(List<List<int>> g) {
    final out = <(int, int)>{};
    for (final s in _horizontalRuns(g)) {
      for (var i = 0; i < s.len; i++) {
        out.add((s.r, s.c0 + i));
      }
    }
    for (final s in _verticalRunsOn(g)) {
      for (var i = 0; i < s.len; i++) {
        out.add((s.r0 + i, s.c));
      }
    }
    return out;
  }

  int _horizontalLenThrough(List<List<int>> g, int r, int c) {
    final n = gridSize;
    if (!_alive(g[r][c])) return 0;
    final mc = tileMatchColor(g[r][c]);
    var len = 1;
    for (var cc = c - 1; cc >= 0 && _alive(g[r][cc]) && tileMatchColor(g[r][cc]) == mc; cc--) {
      len++;
    }
    for (var cc = c + 1; cc < n && _alive(g[r][cc]) && tileMatchColor(g[r][cc]) == mc; cc++) {
      len++;
    }
    return len;
  }

  int _verticalLenThrough(List<List<int>> g, int r, int c) {
    final n = gridSize;
    if (!_alive(g[r][c])) return 0;
    final mc = tileMatchColor(g[r][c]);
    var len = 1;
    for (var rr = r - 1; rr >= 0 && _alive(g[rr][c]) && tileMatchColor(g[rr][c]) == mc; rr--) {
      len++;
    }
    for (var rr = r + 1; rr < n && _alive(g[rr][c]) && tileMatchColor(g[rr][c]) == mc; rr++) {
      len++;
    }
    return len;
  }

  (int, int) _pickPivotOnHorizontal(
    ({int r, int c0, int len}) seg,
    int? pr1,
    int? pc1,
    int? pr2,
    int? pc2,
  ) {
    bool contains(int? pr, int? pc) =>
        pr != null &&
        pc != null &&
        pr == seg.r &&
        pc >= seg.c0 &&
        pc < seg.c0 + seg.len;

    if (contains(pr1, pc1)) return (seg.r, pc1!);
    if (contains(pr2, pc2)) return (seg.r, pc2!);
    return (seg.r, seg.c0 + seg.len ~/ 2);
  }

  (int, int) _pickPivotOnVertical(
    ({int c, int r0, int len}) seg,
    int? pr1,
    int? pc1,
    int? pr2,
    int? pc2,
  ) {
    bool contains(int? pr, int? pc) =>
        pr != null &&
        pc != null &&
        pc == seg.c &&
        pr >= seg.r0 &&
        pr < seg.r0 + seg.len;

    if (contains(pr1, pc1)) return (pr1!, seg.c);
    if (contains(pr2, pc2)) return (pr2!, seg.c);
    return (seg.r0 + seg.len ~/ 2, seg.c);
  }

  bool _horizontalSegSubset(
    ({int r, int c0, int len}) s,
    Set<(int, int)> matched,
  ) {
    for (var i = 0; i < s.len; i++) {
      if (!matched.contains((s.r, s.c0 + i))) return false;
    }
    return true;
  }

  bool _verticalSegSubset(
    ({int c, int r0, int len}) s,
    Set<(int, int)> matched,
  ) {
    for (var i = 0; i < s.len; i++) {
      if (!matched.contains((s.r0 + i, s.c))) return false;
    }
    return true;
  }

  ({
    (int, int)? pivot,
    int? specialKind,
  }) _classifyMatchOutcome(
    Set<(int, int)> matched, {
    int? prefR1,
    int? prefC1,
    int? prefR2,
    int? prefC2,
  }) {
    final g = grid;
    final hs =
        _horizontalRuns(g).where((s) => _horizontalSegSubset(s, matched)).toList();
    final vs =
        _verticalRunsOn(g).where((s) => _verticalSegSubset(s, matched)).toList();

    ({int r, int c0, int len})? bestH;
    for (final s in hs) {
      if (s.len >= 5 && (bestH == null || s.len > bestH.len)) {
        bestH = s;
      }
    }
    ({int c, int r0, int len})? bestV;
    for (final s in vs) {
      if (s.len >= 5 && (bestV == null || s.len > bestV.len)) {
        bestV = s;
      }
    }

    if (bestH != null || bestV != null) {
      if (bestV != null && (bestH == null || bestV.len > bestH.len)) {
        final s = bestV;
        final pivot = _pickPivotOnVertical(
          s,
          prefR1,
          prefC1,
          prefR2,
          prefC2,
        );
        final mc = tileMatchColor(g[pivot.$1][pivot.$2]);
        return (
          pivot: pivot,
          specialKind: encodeSpecial(
            baseColor: mc.clamp(0, tileKinds - 1),
            subtype: specialSubtypeColorBomb,
          ),
        );
      }
      final s = bestH!;
      final pivot = _pickPivotOnHorizontal(
        s,
        prefR1,
        prefC1,
        prefR2,
        prefC2,
      );
      final mc = tileMatchColor(g[pivot.$1][pivot.$2]);
      return (
        pivot: pivot,
        specialKind: encodeSpecial(
          baseColor: mc.clamp(0, tileKinds - 1),
          subtype: specialSubtypeColorBomb,
        ),
      );
    }

    (int, int)? ltPivot;
    for (final cell in matched) {
      final hl = _horizontalLenThrough(g, cell.$1, cell.$2);
      final vl = _verticalLenThrough(g, cell.$1, cell.$2);
      if (hl >= 3 && vl >= 3) {
        ltPivot ??= cell;
        final prefer =
            (prefR1 == cell.$1 && prefC1 == cell.$2) ||
                (prefR2 == cell.$1 && prefC2 == cell.$2);
        if (prefer) {
          ltPivot = cell;
          break;
        }
      }
    }

    if (ltPivot != null) {
      final mc = tileMatchColor(g[ltPivot.$1][ltPivot.$2]);
      return (
        pivot: ltPivot,
        specialKind: encodeSpecial(
          baseColor: mc.clamp(0, tileKinds - 1),
          subtype: specialSubtypeBomb,
        ),
      );
    }

    for (final s in hs) {
      if (s.len == 4) {
        final pivot = _pickPivotOnHorizontal(
          s,
          prefR1,
          prefC1,
          prefR2,
          prefC2,
        );
        final mc = tileMatchColor(g[pivot.$1][pivot.$2]);
        return (
          pivot: pivot,
          specialKind: encodeSpecial(
            baseColor: mc.clamp(0, tileKinds - 1),
            subtype: specialSubtypeLineH,
          ),
        );
      }
    }

    for (final s in vs) {
      if (s.len == 4) {
        final pivot = _pickPivotOnVertical(
          s,
          prefR1,
          prefC1,
          prefR2,
          prefC2,
        );
        final mc = tileMatchColor(g[pivot.$1][pivot.$2]);
        return (
          pivot: pivot,
          specialKind: encodeSpecial(
            baseColor: mc.clamp(0, tileKinds - 1),
            subtype: specialSubtypeLineV,
          ),
        );
      }
    }

    return (pivot: null, specialKind: null);
  }

  Set<(int, int)> _expandSpecialAt(
    int r,
    int c,
    int specialKind,
    int? colorBombPartnerBase,
  ) {
    final n = gridSize;
    final sub = specialSubtype(specialKind);
    final out = <(int, int)>{};

    if (sub == specialSubtypeLineH) {
      for (var cc = 0; cc < n; cc++) {
        if (_alive(grid[r][cc])) out.add((r, cc));
      }
    } else if (sub == specialSubtypeLineV) {
      for (var rr = 0; rr < n; rr++) {
        if (_alive(grid[rr][c])) out.add((rr, c));
      }
    } else if (sub == specialSubtypeBomb) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          final rr = r + dr;
          final cc = c + dc;
          if (rr >= 0 &&
              rr < n &&
              cc >= 0 &&
              cc < n &&
              _alive(grid[rr][cc])) {
            out.add((rr, cc));
          }
        }
      }
    } else if (sub == specialSubtypeColorBomb) {
      final target = colorBombPartnerBase ?? tileMatchColor(specialKind);
      if (target >= 0) {
        for (var rr = 0; rr < n; rr++) {
          for (var cc = 0; cc < n; cc++) {
            final v = grid[rr][cc];
            if (!_alive(v)) continue;
            if (tileMatchColor(v) == target) out.add((rr, cc));
          }
        }
      }
    } else {
      if (_alive(grid[r][c])) out.add((r, c));
    }

    return out;
  }

  void _resolveAllMatches() {
    while (true) {
      final matched = _findMatches(grid);
      if (matched.isEmpty) break;
      removeMatchedCellsMaybeCreateSpecial(matched);
      _applyGravity();
      _fillEmpties();
    }
  }

  void _applyGravity() {
    final n = gridSize;
    for (var c = 0; c < n; c++) {
      final colTiles = <int>[];
      for (var r = n - 1; r >= 0; r--) {
        final v = grid[r][c];
        if (v >= 0) colTiles.add(v);
      }
      var i = 0;
      for (var r = n - 1; r >= 0; r--) {
        grid[r][c] = i < colTiles.length ? colTiles[i] : holeTile;
        i++;
      }
    }
  }

  void _fillEmpties() {
    final n = gridSize;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (grid[r][c] < 0) {
          grid[r][c] = random.nextInt(tileKinds);
        }
      }
    }
  }
}
