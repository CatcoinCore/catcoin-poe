import 'dart:math' as math;
import 'package:flutter/material.dart';

class TriColorRingPainter extends CustomPainter {
  final double rotationAngle;
  final bool isPulsing;

  TriColorRingPainter({
    required this.rotationAngle,
    this.isPulsing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;
    final strokeWidth = 12.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Add glow effect when pulsing
    if (isPulsing) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Draw glow arcs
      _drawArc(canvas, center, radius, 0, glowPaint, Colors.amber.withValues(alpha: 0.3));
      _drawArc(canvas, center, radius, 120, glowPaint, Colors.grey.withValues(alpha: 0.3));
      _drawArc(canvas, center, radius, 240, glowPaint, Colors.brown.withValues(alpha: 0.3));
    }

    // Draw three arcs (120° each)
    _drawArc(canvas, center, radius, 0, paint, Colors.amber); // Gold
    _drawArc(canvas, center, radius, 120, paint, Colors.grey); // Silver
    _drawArc(canvas, center, radius, 240, paint, Colors.brown.shade400); // Bronze
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double startAngle, Paint paint, Color color) {
    paint.color = color;
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    final adjustedStartAngle = (startAngle + rotationAngle) * (math.pi / 180);
    const sweepAngle = 115 * (math.pi / 180); // 115° to leave gaps

    canvas.drawArc(rect, adjustedStartAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(TriColorRingPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle || 
           oldDelegate.isPulsing != isPulsing;
  }
}


