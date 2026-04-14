import 'package:flutter/material.dart';

class SelectionPathPainter extends CustomPainter {
  const SelectionPathPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.nodeRadius,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double nodeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint nodePaint = Paint()
      ..color = color.withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;

    if (points.length == 1) {
      canvas.drawCircle(points.first, nodeRadius * 1.3, nodePaint);
      return;
    }

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);

    for (final Offset point in points) {
      canvas.drawCircle(point, nodeRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SelectionPathPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.nodeRadius != nodeRadius;
  }
}
