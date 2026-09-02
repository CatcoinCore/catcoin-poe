import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'arrow_escape_engine.dart';
import 'arrow_escape_levels.dart';
import 'arrow_escape_models.dart';
import 'arrow_escape_slide_math.dart';

/// Dark neon board; one arrow may animate along its polyline + exit ray
/// ([slideAlongPathProgress]), or bump with a pixel offset ([slidingBumpOffset]).
class ArrowEscapeBoardPainter extends CustomPainter {
  ArrowEscapeBoardPainter({
    required this.engine,
    required this.cellW,
    required this.cellH,
    required this.revision,
    this.paintBleed = 0,
    this.slidingArrowIndex,
    this.slideTravelPx,
    this.headStyleIndex = 0,
  }) : assert(cellW > 0 && cellH > 0);

  final ArrowEscapeEngine engine;
  final double cellW;
  final double cellH;

  /// Bump when mutating [engine] in place so frames repaint.
  final int revision;

  /// Extra pixels around the grid so slide-off paths (beyond board edges) are not
  /// clipped by a tight viewport.
  final double paintBleed;

  final int? slidingArrowIndex;

  /// When non-null, draws [slidingArrowIndex] as a sliding window along its path
  /// (in pixels) for both escapes and bumps.
  final double? slideTravelPx;

  /// Defines the visual style of the arrow head (0: arrow, 1: snake, 2: worm).
  final int headStyleIndex;

  Offset _center(int r, int c, [Offset shift = Offset.zero]) =>
      Offset((c + 0.5) * cellW + shift.dx, (r + 0.5) * cellH + shift.dy);

  Path _polylinePath(List<(int, int)> cells, [Offset shift = Offset.zero]) {
    final p = Path();
    if (cells.isEmpty) return p;
    final first = _center(cells.first.$1, cells.first.$2, shift);
    p.moveTo(first.dx, first.dy);
    for (var i = 1; i < cells.length; i++) {
      final pt = _center(cells[i].$1, cells[i].$2, shift);
      p.lineTo(pt.dx, pt.dy);
    }
    return p;
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    ArrowEscapeDir dir,
    Color color,
    double thickness,
  ) {
    if (headStyleIndex == 1) {
      // Snake head
      final (dr, dc) = arrowEscapeDelta(dir);
      final r = thickness * 0.9;
      final back = Offset(tip.dx - dc * r * 0.5, tip.dy - dr * r * 0.5);
      canvas.drawCircle(back, r, Paint()..color = color);
      
      final perp = Offset(-dr.toDouble(), dc.toDouble());
      final e1 = back + Offset(dc * r * 0.3 + perp.dx * r * 0.4, dr * r * 0.3 + perp.dy * r * 0.4);
      final e2 = back + Offset(dc * r * 0.3 - perp.dx * r * 0.4, dr * r * 0.3 - perp.dy * r * 0.4);
      final eyePaint = Paint()..color = const Color(0xFF0B1020);
      canvas.drawCircle(e1, r * 0.25, eyePaint);
      canvas.drawCircle(e2, r * 0.25, eyePaint);
      return;
    }
    
    if (headStyleIndex == 2) {
      // Earthworm head
      final (dr, dc) = arrowEscapeDelta(dir);
      final r = thickness * 0.85;
      final back = Offset(tip.dx - dc * r * 0.5, tip.dy - dr * r * 0.5);
      canvas.drawCircle(back, r, Paint()..color = color);
      canvas.drawCircle(
        back,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    // Default Pointy Arrow
    final (dr, dc) = arrowEscapeDelta(dir);
    final back = Offset(
      tip.dx - dc * thickness * 1.1,
      tip.dy - dr * thickness * 1.1,
    );
    final perp = Offset(-(tip.dy - back.dy), tip.dx - back.dx);
    final len = math.sqrt(perp.dx * perp.dx + perp.dy * perp.dy);
    if (len < 0.001) return;
    final pn = Offset(
      perp.dx / len * thickness * 0.85,
      perp.dy / len * thickness * 0.85,
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + pn.dx, back.dy + pn.dy)
      ..lineTo(back.dx - pn.dx, back.dy - pn.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintArrow(
    Canvas canvas,
    int arrowIndex,
    Offset shift,
    double lineW,
  ) {
    if (engine.isRemoved(arrowIndex)) return;
    final cells = engine.cellsForArrow(arrowIndex);
    final dir = engine.headDirForArrow(arrowIndex);
    if (cells == null || dir == null || cells.isEmpty) return;

    final color = kArrowEscapeNeonPalette(arrowIndex);
    final path = _polylinePath(cells, shift);

    // No MaskFilter.blur — some Android/Impeller setups drop strokes silently.
    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = lineW * 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.88)
        ..strokeWidth = lineW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = lineW * 0.38
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final head = cells.last;
    final tip = _center(head.$1, head.$2, shift);
    _drawArrowhead(canvas, tip, dir, color, lineW);
  }

  void _paintArrowSlideAlongPath(
    Canvas canvas,
    int arrowIndex,
    double travelPx,
    double lineW,
  ) {
    if (engine.isRemoved(arrowIndex)) return;
    final cells = engine.cellsForArrow(arrowIndex);
    final dir = engine.headDirForArrow(arrowIndex);
    if (cells == null || dir == null || cells.isEmpty) return;

    final stroke = arrowEscapeSlideStrokeAtProgress(
      cells: cells,
      headDir: dir,
      cellW: cellW,
      cellH: cellH,
      travelPx: travelPx,
    );
    if (stroke == null) {
      _paintArrow(canvas, arrowIndex, Offset.zero, lineW);
      return;
    }

    final color = kArrowEscapeNeonPalette(arrowIndex);
    final path = stroke.path;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = lineW * 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.88)
        ..strokeWidth = lineW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = lineW * 0.38
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _drawArrowhead(canvas, stroke.tip, stroke.tipDir, color, lineW);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridW = cellW * engine.cols;
    final gridH = cellH * engine.rows;

    canvas.save();
    canvas.translate(paintBleed, paintBleed);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, gridW, gridH),
      const Radius.circular(14),
    );
    final bg = Paint()..color = const Color(0xFF0B1020);
    canvas.drawRRect(rrect, bg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, math.min(cellW, cellH) * 0.035),
    );

    final lineW = math.min(cellW, cellH) * 0.26;
    final slideIx = slidingArrowIndex;

    for (var i = 0; i < engine.paths.length; i++) {
      if (slideIx != null && i == slideIx) continue;
      _paintArrow(canvas, i, Offset.zero, lineW);
    }

    if (slideIx != null && !engine.isRemoved(slideIx)) {
      final travelPx = slideTravelPx;
      if (travelPx != null) {
        _paintArrowSlideAlongPath(canvas, slideIx, travelPx, lineW);
      } else {
        _paintArrow(canvas, slideIx, Offset.zero, lineW);
      }
    }

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final dotR = math.min(cellW, cellH) * 0.06;
    for (var r = 0; r < engine.rows; r++) {
      for (var c = 0; c < engine.cols; c++) {
        canvas.drawCircle(_center(r, c), dotR, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowEscapeBoardPainter oldDelegate) {
    return oldDelegate.revision != revision ||
        oldDelegate.engine != engine ||
        oldDelegate.cellW != cellW ||
        oldDelegate.cellH != cellH ||
        oldDelegate.paintBleed != paintBleed ||
        oldDelegate.slidingArrowIndex != slidingArrowIndex ||
        oldDelegate.slideTravelPx != slideTravelPx ||
        oldDelegate.headStyleIndex != headStyleIndex;
  }
}
