import 'package:flutter/material.dart';

import '../models/cell_pos.dart';

class BoardLatticePainter extends CustomPainter {
  const BoardLatticePainter({
    required this.count,
    required this.gap,
    required this.lineColor,
    this.activeCells,
  });

  final int count;
  final double gap;
  final Color lineColor;
  final Set<CellPos>? activeCells;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 1) {
      return;
    }

    final double tile = (size.width - gap * (count - 1)) / count;

    if (activeCells != null) {
      final Paint cellPaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final Radius radius = Radius.circular(tile * 0.18);

      for (int row = 0; row < count; row++) {
        for (int col = 0; col < count; col++) {
          final CellPos cell = CellPos(row, col);
          if (!activeCells!.contains(cell)) {
            continue;
          }
          final Rect rect = Rect.fromLTWH(
            col * (tile + gap),
            row * (tile + gap),
            tile,
            tile,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), cellPaint);
        }
      }
      return;
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = gap < 1 ? 1 : gap
      ..style = PaintingStyle.stroke;

    for (int index = 1; index < count; index++) {
      final double offset = tile * index + gap * (index - 0.5);
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardLatticePainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.gap != gap ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.activeCells != activeCells;
  }
}
