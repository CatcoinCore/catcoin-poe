import 'arrow_escape_engine.dart';

/// DFS + memo: solvable iff some sequence of legal escapes clears the board.
class ArrowEscapeSolver {
  ArrowEscapeSolver._();

  static final Map<String, bool> _memo = {};

  static bool isSolvable(ArrowEscapeEngine engine) {
    final copy = engine.clone();
    return _dfs(copy);
  }

  static void clearMemo() => _memo.clear();

  static String _gridKey(ArrowEscapeEngine e) {
    final b = StringBuffer();
    for (var r = 0; r < e.rows; r++) {
      for (var c = 0; c < e.cols; c++) {
        final v = e.arrowIdAt(r, c);
        b.write(v == null ? '.' : String.fromCharCode(97 + v));
      }
    }
    for (var i = 0; i < e.paths.length; i++) {
      b.write(e.isRemoved(i) ? '1' : '0');
    }
    return b.toString();
  }

  static bool _dfs(ArrowEscapeEngine eng) {
    final key = _gridKey(eng);
    final hit = _memo[key];
    if (hit != null) return hit;

    if (eng.isClear) {
      _memo[key] = true;
      return true;
    }

    for (var i = 0; i < eng.paths.length; i++) {
      if (eng.isRemoved(i)) continue;
      if (!eng.canEscapeArrow(i)) continue;
      final next = eng.clone();
      if (!next.tryEscapeArrowByIndex(i)) continue;
      if (_dfs(next)) {
        _memo[key] = true;
        return true;
      }
    }
    _memo[key] = false;
    return false;
  }
}
