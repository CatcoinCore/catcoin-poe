import 'arrow_escape_models.dart';

/// Mutable puzzle: multi-segment arrows on a grid. Tap any cell of an arrow to
/// try to slide it off along the head ray — blocked if another arrow occupies
/// any cell on that ray before the edge (Arrow Escape / Arrow Puzzle style).
class ArrowEscapeEngine {
  ArrowEscapeEngine._({
    required this.rows,
    required this.cols,
    required this.paths,
    required List<List<int?>> grid,
    required this.initialArrowCount,
    required this.maxLives,
    List<bool>? removedCopy,
    int? livesCopy,
    int? escapesCopy,
  })  : _grid = grid,
        _removed =
            removedCopy ?? List<bool>.filled(paths.length, false),
        lives = livesCopy ?? maxLives,
        successfulEscapes = escapesCopy ?? 0;

  factory ArrowEscapeEngine.fromLevel(
    ArrowEscapeLevelDef level, {
    int maxLives = 3,
  }) {
    _validateLevel(level);
    final grid = List.generate(
      level.rows,
      (_) => List<int?>.filled(level.cols, null),
    );
    for (var i = 0; i < level.paths.length; i++) {
      final p = level.paths[i];
      for (final cell in p.cells) {
        final r = cell.$1;
        final c = cell.$2;
        if (grid[r][c] != null) {
          throw ArgumentError(
            'ArrowEscapeEngine: overlapping arrows at ($r,$c)',
          );
        }
        grid[r][c] = i;
      }
    }

    final pathsCopy = [
      for (final p in level.paths)
        ArrowPathDef(cells: List.from(p.cells), headDir: p.headDir),
    ];

    return ArrowEscapeEngine._(
      rows: level.rows,
      cols: level.cols,
      paths: pathsCopy,
      grid: grid,
      initialArrowCount: level.paths.length,
      maxLives: maxLives,
    );
  }

  /// Deep copy for simulation / solver.
  ArrowEscapeEngine clone() {
    final gridCopy = [
      for (final row in _grid) List<int?>.from(row),
    ];
    final pathsCopy = [
      for (final p in paths)
        ArrowPathDef(
          cells: List<(int, int)>.from(p.cells),
          headDir: p.headDir,
        ),
    ];
    return ArrowEscapeEngine._(
      rows: rows,
      cols: cols,
      paths: pathsCopy,
      grid: gridCopy,
      initialArrowCount: initialArrowCount,
      maxLives: maxLives,
      removedCopy: List<bool>.from(_removed),
      livesCopy: lives,
      escapesCopy: successfulEscapes,
    );
  }

  /// Legacy single-character-per-cell levels (`^v<>` one cell per arrow).
  factory ArrowEscapeEngine.fromRows(
    List<String> rowStrings, {
    int maxLives = 3,
  }) {
    final paths = <ArrowPathDef>[];
    for (var r = 0; r < rowStrings.length; r++) {
      final row = rowStrings[r];
      for (var c = 0; c < row.length; c++) {
        final dir = arrowEscapeDirFromChar(row[c]);
        if (dir != null) {
          paths.add(ArrowPathDef(cells: [(r, c)], headDir: dir));
        }
      }
    }
    return ArrowEscapeEngine.fromLevel(
      ArrowEscapeLevelDef(
        rows: rowStrings.length,
        cols: rowStrings.isEmpty ? 0 : rowStrings.first.length,
        paths: paths,
        name: 'legacy_ascii',
      ),
      maxLives: maxLives,
    );
  }

  final int rows;
  final int cols;
  final List<ArrowPathDef> paths;
  final int initialArrowCount;
  final int maxLives;

  final List<List<int?>> _grid;
  int lives;
  int successfulEscapes;

  final List<bool> _removed;

  List<List<int?>> get grid => _grid;

  @override
  String toString() => 'ArrowEscapeEngine ${rows}x$cols arrows=$initialArrowCount';

  static void _validateLevel(ArrowEscapeLevelDef level) {
    for (var pi = 0; pi < level.paths.length; pi++) {
      final p = level.paths[pi];
      if (p.cells.isEmpty) {
        throw ArgumentError('Arrow $pi has empty cells');
      }
      for (final cell in p.cells) {
        final r = cell.$1;
        final c = cell.$2;
        if (r < 0 ||
            r >= level.rows ||
            c < 0 ||
            c >= level.cols) {
          throw ArgumentError('Arrow $pi out of bounds ($r,$c)');
        }
      }
      for (var i = 1; i < p.cells.length; i++) {
        final a = p.cells[i - 1];
        final b = p.cells[i];
        final dr = (a.$1 - b.$1).abs();
        final dc = (a.$2 - b.$2).abs();
        if (dr + dc != 1) {
          throw ArgumentError(
            'Arrow $pi non-adjacent step $a → $b',
          );
        }
      }

      if (p.cells.length >= 2) {
        final incoming = arrowEscapeDirBetween(
          p.cells[p.cells.length - 2],
          p.cells[p.cells.length - 1],
        );
        if (incoming != p.headDir) {
          throw ArgumentError(
            'Arrow $pi headDir ${p.headDir} must match last segment $incoming',
          );
        }
      }

      final head = p.cells.last;
      final body = p.cells.length > 1
          ? p.cells.sublist(0, p.cells.length - 1).toSet()
          : <(int, int)>{};
      final (dr, dc) = arrowEscapeDelta(p.headDir);
      var r = head.$1 + dr;
      var c = head.$2 + dc;
      while (r >= 0 && r < level.rows && c >= 0 && c < level.cols) {
        if (body.contains((r, c))) {
          throw ArgumentError(
            'Arrow $pi head ray folds back through body at ($r,$c)',
          );
        }
        r += dr;
        c += dc;
      }
    }
  }

  int get arrowsRemaining {
    var n = 0;
    for (var i = 0; i < paths.length; i++) {
      if (!_removed[i]) n++;
    }
    return n;
  }

  bool get isClear => arrowsRemaining == 0;

  bool isRemoved(int arrowIndex) {
    return arrowIndex < 0 ||
        arrowIndex >= _removed.length ||
        _removed[arrowIndex];
  }

  bool canEscapeArrow(int arrowIndex) {
    if (isRemoved(arrowIndex)) return false;
    final p = paths[arrowIndex];
    final head = p.cells.last;
    final (dr, dc) = arrowEscapeDelta(p.headDir);
    var r = head.$1 + dr;
    var c = head.$2 + dc;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final occ = _grid[r][c];
      if (occ != null && occ != arrowIndex) return false;
      r += dr;
      c += dc;
    }
    return true;
  }

  /// Escape using arrow index (same rules as [tryEscape] on its head cell).
  bool tryEscapeArrowByIndex(int arrowIndex) {
    if (isRemoved(arrowIndex)) return false;
    final cells = paths[arrowIndex].cells;
    if (cells.isEmpty) return false;
    final head = cells.last;
    return tryEscape(head.$1, head.$2);
  }

  /// Returns false if blocked or empty — caller should decrement life on false.
  bool tryEscape(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
    final id = _grid[r][c];
    if (id == null || isRemoved(id)) return false;
    if (!canEscapeArrow(id)) return false;

    final cells = paths[id].cells;
    for (final cell in cells) {
      _grid[cell.$1][cell.$2] = null;
    }
    _removed[id] = true;
    successfulEscapes++;
    return true;
  }

  void loseLife() {
    lives = (lives - 1).clamp(0, maxLives);
  }

  /// Cells for arrow [arrowIndex] if still on board (tail → head).
  List<(int, int)>? cellsForArrow(int arrowIndex) {
    if (isRemoved(arrowIndex)) return null;
    return paths[arrowIndex].cells;
  }

  ArrowEscapeDir? headDirForArrow(int arrowIndex) {
    if (isRemoved(arrowIndex)) return null;
    return paths[arrowIndex].headDir;
  }

  int? arrowIdAt(int r, int c) => _grid[r][c];
}
