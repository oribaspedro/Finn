import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSegment {
  final double value;
  final Color color;
  const DonutSegment(this.value, this.color);
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Color? trackColor;
  final double? maxValue; // se nulo, usa a soma dos segmentos
  final Widget? center;

  const DonutChart({
    super.key,
    required this.segments,
    required this.size,
    required this.strokeWidth,
    this.trackColor,
    this.maxValue,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments, strokeWidth, trackColor, maxValue),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color? trackColor;
  final double? maxValue;

  _DonutPainter(this.segments, this.strokeWidth, this.trackColor, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (trackColor != null) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor!);
    }

    final total = maxValue ?? segments.fold<double>(0, (s, e) => s + e.value);
    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.value / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, paint..color = seg.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.maxValue != maxValue;
}
