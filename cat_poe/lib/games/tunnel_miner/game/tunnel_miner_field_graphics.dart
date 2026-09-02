import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/tunnel_miner_models.dart';

/// Pure Canvas helpers for Tunnel Miner tiles (no Flame imports).
class TunnelMinerFieldGraphics {
  TunnelMinerFieldGraphics._();

  static void paintDepthBackdrop({
    required Canvas canvas,
    required Rect bounds,
    required double scrollNormalized,
  }) {
    final base = Color.lerp(
      const Color(0xFF0A0E14),
      const Color(0xFF151D28),
      scrollNormalized.clamp(0.0, 1.0),
    )!;
    final top = Color.lerp(base, const Color(0xFF1A2838), 0.35)!;
    final g = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, base],
    );
    canvas.drawRect(bounds, Paint()..shader = g.createShader(bounds));
  }

  static void paintGridLines(Canvas canvas, Rect bounds, double cell) {
    final p = Paint()
      ..color = const Color(0xFF1F2A38).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final cols = (bounds.width / cell).floor();
    final rows = (bounds.height / cell).floor();
    for (var c = 0; c <= cols; c++) {
      final x = bounds.left + c * cell;
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), p);
    }
    for (var r = 0; r <= rows; r++) {
      final y = bounds.top + r * cell;
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), p);
    }
  }

  static void paintTile({
    required Canvas canvas,
    required TileKind kind,
    required Rect rect,
    required double lavaPulse,
    required int row,
    required int col,
  }) {
    switch (kind) {
      case TileKind.air:
        _paintAir(canvas, rect, row, col);
        break;
      case TileKind.dirt:
        _paintDirt(canvas, rect, row, col);
        break;
      case TileKind.rock:
        _paintRock(canvas, rect, row, col);
        break;
      case TileKind.lava:
        _paintFireHazard(canvas, rect, lavaPulse);
        break;
      case TileKind.ore:
        _paintCatcoin(canvas, rect, lavaPulse);
        break;
      case TileKind.exit:
        _paintExit(canvas, rect, lavaPulse);
        break;
    }
  }

  static void _paintAir(Canvas canvas, Rect rect, int row, int col) {
    final spot = ((row * 31 + col * 17) & 0xff) / 255.0;
    final fill = Color.lerp(
      const Color(0xFF131B26),
      const Color(0xFF182232),
      spot,
    )!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = fill,
    );
  }

  static void _paintDirt(Canvas canvas, Rect rect, int row, int col) {
    final base = const Color(0xFF5D4037);
    final hi = const Color(0xFF795548);
    final lo = const Color(0xFF3E2723);
    final rr = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(5));
    final g = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [hi, base, lo],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRRect(rr, Paint()..shader = g.createShader(rect));
    final speck = Paint()
      ..color = Colors.black.withValues(alpha: 0.12 + ((row + col) & 3) * 0.02);
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.35, rect.top + rect.height * 0.4),
      1.2,
      speck,
    );
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.62, rect.top + rect.height * 0.58),
      1.0,
      speck,
    );
  }

  static void _paintRock(Canvas canvas, Rect rect, int row, int col) {
    final rr = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4));
    final base = const Color(0xFF546E7A);
    final shadow = const Color(0xFF37474F);
    final highlight = const Color(0xFF78909C);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, base, shadow],
        ).createShader(rect),
    );
    final hatch = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final step = 6.0;
    final seed = (row + col * 3) % 4;
    for (double i = -rect.height; i < rect.width + rect.height; i += step) {
      final o = i + seed.toDouble();
      canvas.drawLine(
        Offset(rect.left + o, rect.top),
        Offset(rect.left + o + rect.height * 0.55, rect.bottom),
        hatch,
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  /// Hazard tile drawn as fire (not a flat “lava block”).
  static void _paintFireHazard(Canvas canvas, Rect rect, double pulse) {
    final pad = rect.deflate(1);
    final rr = RRect.fromRectAndRadius(pad, const Radius.circular(5));

    canvas.save();
    canvas.clipRRect(rr);

    final flicker = 0.92 + 0.08 * math.sin(pulse * math.pi * 2 * 2.4);

    // Charcoal / ember bed at bottom
    final bed = Rect.fromLTWH(
      pad.left,
      pad.bottom - pad.height * 0.42,
      pad.width,
      pad.height * 0.45,
    );
    canvas.drawRect(
      bed,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF424242),
            const Color(0xFF212121),
          ],
        ).createShader(bed),
    );

    void flameLobe(double anchorX, double scale, double phaseShift) {
      final wobble =
          math.sin(pulse * math.pi * 2 * 1.9 + phaseShift) * 2.5 * flicker;
      final tipY = pad.top + 5 + (1.0 - flicker) * 6;
      final baseY = pad.bottom - 3;
      final hw = 9.0 * scale;

      final path = Path()
        ..moveTo(anchorX - hw * 0.35, baseY)
        ..quadraticBezierTo(
          anchorX - hw + wobble,
          pad.center.dy,
          anchorX + wobble * 0.4,
          tipY,
        )
        ..quadraticBezierTo(
          anchorX + hw + wobble * 0.3,
          pad.center.dy,
          anchorX + hw * 0.35,
          baseY,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFB71C1C),
              const Color(0xFFFF5722),
              Color.lerp(
                    const Color(0xFFFFEB3B),
                    const Color(0xFFFFFFFF),
                    0.35 + 0.25 * flicker,
                  )!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromLTRB(pad.left, tipY, pad.right, baseY)),
      );
    }

    final cx = pad.center.dx;
    flameLobe(cx - pad.width * 0.22, 1.0, 0.0);
    flameLobe(cx, 1.15, 1.1);
    flameLobe(cx + pad.width * 0.22, 1.0, 2.0);

    // Inner bright core (gas flame highlight)
    final hl = Rect.fromCenter(
      center: Offset(cx, pad.top + pad.height * 0.38),
      width: pad.width * 0.22,
      height: pad.height * 0.35,
    );
    canvas.drawOval(
      hl,
      Paint()
        ..color =
            const Color(0xFFFFF59D).withValues(alpha: 0.28 + 0.18 * flicker),
    );

    canvas.restore();

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFF7043).withValues(alpha: 0.55),
    );
  }

  /// Collectible ore tile drawn as a CatCoin-style token (not a gold bar).
  static void _paintCatcoin(Canvas canvas, Rect rect, double pulse) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = rect.shortestSide * 0.38;
    final shimmer = 0.5 + 0.5 * math.sin(pulse * 4);

    // Outer rim — brushed metal
    canvas.drawCircle(
      Offset(cx, cy),
      r + 1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB0BEC5),
            const Color(0xFF546E7A),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r + 1)),
    );

    // Orange CatCoin face
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.05,
          colors: [
            Color.lerp(const Color(0xFFFFB74D), const Color(0xFFFF9800), shimmer)!,
            const Color(0xFFE65100),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Inner inset ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black.withValues(alpha: 0.22),
    );

    // Stylized “C” + ears silhouette (CatCoin mark)
    final faceR = r * 0.62;
    final earPaint = Paint()
      ..color = const Color(0xFFBF360C).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(cx - faceR * 0.55, cy - faceR * 0.85)
        ..lineTo(cx - faceR * 0.25, cy - faceR * 0.95)
        ..lineTo(cx - faceR * 0.15, cy - faceR * 0.55)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + faceR * 0.55, cy - faceR * 0.85)
        ..lineTo(cx + faceR * 0.25, cy - faceR * 0.95)
        ..lineTo(cx + faceR * 0.15, cy - faceR * 0.55)
        ..close(),
      earPaint,
    );

    final cPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx + faceR * 0.08, cy), radius: faceR * 0.72),
        math.pi * 0.35,
        math.pi * 1.35,
      );
    canvas.drawPath(
      cPath,
      Paint()
        ..color = const Color(0xFFFFF8E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, r * 0.14)
        ..strokeCap = StrokeCap.round,
    );

    // Specular highlight on rim
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r * 0.35, cy - r * 0.35), radius: r * 0.45),
      -math.pi * 0.15,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  static void _paintExit(Canvas canvas, Rect rect, double pulse) {
    final rr = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(6));
    final pulseGlow = 0.65 + 0.35 * math.sin(pulse * 4).abs();
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF69F0AE),
            const Color(0xFF00C853),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.lerp(
              const Color(0xFFB9F6CA),
              const Color(0xFFFFFFFF),
              (pulseGlow - 0.65).clamp(0.0, 1.0),
            )!
            .withValues(alpha: 0.9),
    );
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final d = rect.shortestSide * 0.22;
    canvas.drawLine(Offset(cx - d, cy), Offset(cx + d, cy), cross);
    canvas.drawLine(Offset(cx, cy - d), Offset(cx, cy + d), cross);
  }

  static void paintPlayer(Canvas canvas, Rect rect) {
    final outer = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final shadowRect = outer.outerRect.shift(const Offset(1.5, 2));
    final shadow =
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(10));
    canvas.drawRRect(
      shadow,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      outer,
      Paint()..color = const Color(0xFFE65100),
    );
    final inner = RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(7));
    canvas.drawRRect(inner, Paint()..color = const Color(0xFFFFE0B2));
    final earL = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + rect.width * 0.18, rect.top - 2, 7, 9),
      const Radius.circular(3),
    );
    final earR = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.right - rect.width * 0.18 - 7, rect.top - 2, 7, 9),
      const Radius.circular(3),
    );
    canvas.drawRRect(earL, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawRRect(earR, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawCircle(
      Offset(rect.center.dx - 5, rect.center.dy - 1),
      2,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawCircle(
      Offset(rect.center.dx + 5, rect.center.dy - 1),
      2,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }
}
