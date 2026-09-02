/// Grid arrow directions — exit ray follows [headDir] from the path **head**
/// (last cell in [ArrowPathDef.cells]).
enum ArrowEscapeDir {
  up,
  down,
  left,
  right,
}

ArrowEscapeDir? arrowEscapeDirFromChar(String ch) {
  switch (ch) {
    case '^':
      return ArrowEscapeDir.up;
    case 'v':
    case 'V':
      return ArrowEscapeDir.down;
    case '<':
      return ArrowEscapeDir.left;
    case '>':
      return ArrowEscapeDir.right;
    default:
      return null;
  }
}

/// One polyline arrow: [cells] run **tail → head** (last cell carries the tip).
class ArrowPathDef {
  const ArrowPathDef({
    required this.cells,
    required this.headDir,
  }) : assert(cells.length >= 1, 'Arrow needs at least one cell');

  final List<(int r, int c)> cells;
  final ArrowEscapeDir headDir;
}

/// Full board definition for [ArrowEscapeEngine.fromLevel].
class ArrowEscapeLevelDef {
  const ArrowEscapeLevelDef({
    required this.rows,
    required this.cols,
    required this.paths,
    this.name,
  });

  final int rows;
  final int cols;
  final List<ArrowPathDef> paths;

  /// Optional label for debugging / future UI.
  final String? name;

  int get arrowCount => paths.length;
}

(int dr, int dc) arrowEscapeDelta(ArrowEscapeDir d) {
  switch (d) {
    case ArrowEscapeDir.up:
      return (-1, 0);
    case ArrowEscapeDir.down:
      return (1, 0);
    case ArrowEscapeDir.left:
      return (0, -1);
    case ArrowEscapeDir.right:
      return (0, 1);
  }
}

/// Direction from [from] to [to] (orthogonal neighbors only).
ArrowEscapeDir? arrowEscapeDirBetween((int r, int c) from, (int r, int c) to) {
  final dr = to.$1 - from.$1;
  final dc = to.$2 - from.$2;
  if (dr == -1 && dc == 0) return ArrowEscapeDir.up;
  if (dr == 1 && dc == 0) return ArrowEscapeDir.down;
  if (dr == 0 && dc == -1) return ArrowEscapeDir.left;
  if (dr == 0 && dc == 1) return ArrowEscapeDir.right;
  return null;
}
