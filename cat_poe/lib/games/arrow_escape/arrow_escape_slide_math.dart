import 'dart:math' as math;
import 'dart:ui' show Offset, Path;

import 'arrow_escape_engine.dart';
import 'arrow_escape_models.dart';

/// Tail → head polyline through cell centers (pixel space).
Path arrowEscapeBodyPathPx(
  List<(int, int)> cells,
  double cellW,
  double cellH,
) {
  final p = Path();
  if (cells.isEmpty) return p;
  double cx(int c) => (c + 0.5) * cellW;
  double cy(int r) => (r + 0.5) * cellH;
  p.moveTo(cx(cells.first.$2), cy(cells.first.$1));
  for (var i = 1; i < cells.length; i++) {
    p.lineTo(cx(cells[i].$2), cy(cells[i].$1));
  }
  return p;
}

/// [arrowEscapeBodyPathPx] plus [exitCells] steps along [headDir] from the head.
Path arrowEscapeExtendedSlidePathPx(
  List<(int, int)> cells,
  ArrowEscapeDir headDir,
  double cellW,
  double cellH,
  int exitCells,
) {
  final p = arrowEscapeBodyPathPx(cells, cellW, cellH);
  if (cells.isEmpty || exitCells <= 0) return p;
  final (dr, dc) = arrowEscapeDelta(headDir);
  var r = cells.last.$1;
  var c = cells.last.$2;
  for (var k = 0; k < exitCells; k++) {
    r += dr;
    c += dc;
    p.lineTo((c + 0.5) * cellW, (r + 0.5) * cellH);
  }
  return p;
}

ArrowEscapeDir? arrowEscapeDirFromTangentVector(Offset v) {
  final len2 = v.dx * v.dx + v.dy * v.dy;
  if (len2 < 1e-12) return null;
  if (v.dx.abs() >= v.dy.abs()) {
    return v.dx > 0 ? ArrowEscapeDir.right : ArrowEscapeDir.left;
  }
  return v.dy > 0 ? ArrowEscapeDir.down : ArrowEscapeDir.up;
}

/// Visible arrow stroke while sliding off: moves along the bent path, then
/// straight along the exit ray (not a rigid translation of the whole shape).
({Path path, Offset tip, ArrowEscapeDir tipDir})? arrowEscapeSlideStrokeAtProgress({
  required List<(int, int)> cells,
  required ArrowEscapeDir headDir,
  required double cellW,
  required double cellH,
  required double travelPx,
}) {
  if (cells.isEmpty || cellW <= 0 || cellH <= 0) return null;

  final points = <Offset>[];
  for (final c in cells) {
    points.add(Offset((c.$2 + 0.5) * cellW, (c.$1 + 0.5) * cellH));
  }

  final exitCells = (travelPx / math.min(cellW, cellH)).ceil() + 1;
  if (exitCells > 0) {
    final (dr, dc) = arrowEscapeDelta(headDir);
    var r = cells.last.$1;
    var c = cells.last.$2;
    for (var k = 0; k < exitCells; k++) {
      r += dr;
      c += dc;
      points.add(Offset((c + 0.5) * cellW, (r + 0.5) * cellH));
    }
  }

  double bodyLen = 0.0;
  for (int i = 0; i < cells.length - 1; i++) {
    bodyLen += (points[i + 1] - points[i]).distance;
  }

  if (bodyLen <= 1e-6) return null;

  final windowStart = math.max(0.0, travelPx);
  final windowEnd = windowStart + bodyLen;

  final slice = Path();
  double currentD = 0.0;
  bool isFirst = true;

  Offset tip = points.last;
  ArrowEscapeDir tipDir = headDir;

  for (int i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];
    final segVec = p2 - p1;
    final segLen = segVec.distance;

    if (segLen <= 1e-6) continue;

    final segStartD = currentD;
    final segEndD = currentD + segLen;

    if (windowEnd > segStartD && windowStart < segEndD) {
      final overlapStart = math.max(windowStart, segStartD);
      final overlapEnd = math.min(windowEnd, segEndD);

      final t1 = (overlapStart - segStartD) / segLen;
      final t2 = (overlapEnd - segStartD) / segLen;

      final pStart = p1 + segVec * t1;
      final pEnd = p1 + segVec * t2;

      if (isFirst) {
        slice.moveTo(pStart.dx, pStart.dy);
        isFirst = false;
      } else {
        slice.lineTo(pStart.dx, pStart.dy);
      }
      slice.lineTo(pEnd.dx, pEnd.dy);

      if ((overlapEnd - windowEnd).abs() < 1e-3) {
        tip = pEnd;
        tipDir = arrowEscapeDirFromTangentVector(segVec) ?? headDir;
      }
    }

    currentD = segEndD;
  }

  return (path: slice, tip: tip, tipDir: tipDir);
}

/// Pixel distance the slide window travels (for animation timing).
double arrowEscapeSlideTravelPx({
  required List<(int, int)> cells,
  required ArrowEscapeDir headDir,
  required double cellW,
  required double cellH,
  required int exitCells,
}) {
  final (dr, dc) = arrowEscapeDelta(headDir);
  final dx = dc * exitCells * cellW;
  final dy = dr * exitCells * cellH;
  return math.sqrt(dx * dx + dy * dy);
}

int arrowRigidExitSteps(ArrowEscapeEngine engine, int arrowIndex) {
  final cells = engine.cellsForArrow(arrowIndex);
  if (cells == null || cells.isEmpty) return 0;
  final dir = engine.headDirForArrow(arrowIndex);
  if (dir == null) return 0;
  final (dr, dc) = arrowEscapeDelta(dir);

  final head = cells.last;
  var s = 0;
  while (true) {
    final nr = head.$1 + s * dr;
    final nc = head.$2 + s * dc;
    if (nr < 0 || nr >= engine.rows || nc < 0 || nc >= engine.cols) {
      break;
    }
    s++;
  }
  return s + cells.length;
}

/// How many whole-cell steps the head can move along its ray over **empty**
/// cells (no other arrow) before hitting an obstacle or leaving the board.
/// 0 means the first step from the head is blocked.
int arrowHeadRayClearSteps(ArrowEscapeEngine engine, int arrowIndex) {
  final cells = engine.cellsForArrow(arrowIndex);
  if (cells == null || cells.isEmpty) return 0;
  final dir = engine.headDirForArrow(arrowIndex);
  if (dir == null) return 0;
  final head = cells.last;
  final (dr, dc) = arrowEscapeDelta(dir);

  var k = 0;
  var r = head.$1 + dr;
  var c = head.$2 + dc;
  while (r >= 0 && r < engine.rows && c >= 0 && c < engine.cols) {
    final occ = engine.arrowIdAt(r, c);
    if (occ != null && occ != arrowIndex) {
      return k;
    }
    k++;
    r += dr;
    c += dc;
  }
  return k;
}
