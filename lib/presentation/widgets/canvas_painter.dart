import 'package:flutter/material.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Custom painter that renders drawing strokes on the canvas.
///
/// This painter efficiently renders all strokes from a [DrawingData] entity
/// plus an optional current stroke being drawn. It implements smart repainting
/// logic to minimize unnecessary redraws.
class CanvasPainter extends CustomPainter {
  /// Creates a canvas painter.
  ///
  /// Parameters:
  /// - [drawingData]: The complete drawing data with all finalized strokes
  /// - [currentStroke]: Optional stroke currently being drawn (not yet finalized)
  const CanvasPainter({
    required this.drawingData,
    this.currentStroke,
  });

  /// The drawing data containing all finalized strokes.
  final DrawingData drawingData;

  /// The stroke currently being drawn (if any).
  final DrawingStroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all finalized strokes
    for (final stroke in drawingData.strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw the current stroke being drawn (if any)
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  /// Draws a single stroke on the canvas.
  ///
  /// Creates a Path from the stroke's points and draws it with the
  /// stroke's color and width properties.
  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    // Create paint with the stroke's properties
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Handle single point (draw a dot)
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Create path from points
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    // Draw the path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    // Repaint if:
    // 1. The number of strokes changed (stroke added/removed/undone/redone)
    // 2. The drawing version changed (indicates a modification)
    // 3. The current stroke changed (user is actively drawing)
    // 4. The current stroke has different number of points (drawing in progress)

    final strokeCountChanged =
        drawingData.strokeCount != oldDelegate.drawingData.strokeCount;

    final versionChanged =
        drawingData.version != oldDelegate.drawingData.version;

    final currentStrokeChanged =
        currentStroke != oldDelegate.currentStroke;

    final currentStrokePointsChanged =
        (currentStroke?.points.length ?? 0) !=
        (oldDelegate.currentStroke?.points.length ?? 0);

    return strokeCountChanged ||
           versionChanged ||
           currentStrokeChanged ||
           currentStrokePointsChanged;
  }
}
