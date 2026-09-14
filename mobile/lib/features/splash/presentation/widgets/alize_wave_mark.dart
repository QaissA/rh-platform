import 'dart:math' as math;

import 'package:flutter/material.dart';

class AlizeWaveMark extends StatelessWidget {
  const AlizeWaveMark({
    super.key,
    required this.progress,
    required this.color,
    this.size = 72,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AlizeWaveMarkPainter(
          progress: progress,
          color: color,
        ),
      ),
    );
  }
}

class _AlizeWaveMarkPainter extends CustomPainter {
  const _AlizeWaveMarkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const double _viewBoxSize = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final clamped = progress.clamp(0.0, 1.0);
    final scale = math.min(size.width, size.height) / _viewBoxSize;
    final dx = (size.width - (_viewBoxSize * scale)) / 2;
    final dy = (size.height - (_viewBoxSize * scale)) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final topProgress = (clamped * 2).clamp(0.0, 1.0);
    final bottomProgress = ((clamped - 0.5) * 2).clamp(0.0, 1.0);

    _drawPartialStroke(
      canvas: canvas,
      paint: paint,
      path: _topPath(),
      pathProgress: topProgress,
    );
    _drawPartialStroke(
      canvas: canvas,
      paint: paint,
      path: _bottomPath(),
      pathProgress: bottomProgress,
    );

    canvas.restore();
  }

  void _drawPartialStroke({
    required Canvas canvas,
    required Paint paint,
    required Path path,
    required double pathProgress,
  }) {
    if (pathProgress <= 0) return;
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) return;
    final segment = metric.extractPath(0, metric.length * pathProgress);
    canvas.drawPath(segment, paint);
  }

  Path _topPath() {
    return Path()
      ..moveTo(3, 14)
      ..cubicTo(7, 8, 11, 20, 15, 14)
      ..cubicTo(19, 8, 20, 10, 21, 12);
  }

  Path _bottomPath() {
    return Path()
      ..moveTo(3, 19)
      ..cubicTo(7, 13, 11, 25, 15, 19)
      ..cubicTo(19, 13, 20, 15, 21, 17);
  }

  @override
  bool shouldRepaint(covariant _AlizeWaveMarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
