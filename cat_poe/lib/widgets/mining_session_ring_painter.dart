import 'dart:math' as math;
import 'package:flutter/material.dart';

class MiningSessionRingPainter extends CustomPainter {
  final double sessionDurationPercentage; // Session duration as % of 24 hours
  final double elapsedPercentage; // Elapsed time as % of session duration

  MiningSessionRingPainter({
    required this.sessionDurationPercentage,
    required this.elapsedPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;
    final strokeWidth = 12.0;

    // First ring: Grey background (full 24 hours)
    final greyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade300
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, greyPaint);

    // Second ring: Light orange (session duration portion of 24 hours)
    if (sessionDurationPercentage > 0) {
      final lightOrangePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.orange.shade200
        ..strokeCap = StrokeCap.round;
      
      final sessionSweepAngle = (sessionDurationPercentage * 360) * (math.pi / 180);
      const startAngle = -math.pi / 2; // Start from top
      
      canvas.drawArc(rect, startAngle, sessionSweepAngle, false, lightOrangePaint);
    }

    // Third ring: Orange (elapsed time portion of session)
    if (elapsedPercentage > 0) {
      final orangePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.orange.shade600
        ..strokeCap = StrokeCap.round;
      
      final elapsedSweepAngle = (elapsedPercentage * sessionDurationPercentage * 360) * (math.pi / 180);
      const startAngle = -math.pi / 2; // Start from top
      
      canvas.drawArc(rect, startAngle, elapsedSweepAngle, false, orangePaint);
    }
  }

  @override
  bool shouldRepaint(MiningSessionRingPainter oldDelegate) {
    return oldDelegate.sessionDurationPercentage != sessionDurationPercentage || 
           oldDelegate.elapsedPercentage != elapsedPercentage;
  }
}


