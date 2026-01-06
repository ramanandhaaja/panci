import 'package:flutter/material.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Custom painter that renders a preview of drawing strokes.
///
/// This painter efficiently renders drawing strokes in a thumbnail/preview
/// format for use in canvas list views. It's similar to CanvasPainter but
/// optimized for small preview sizes.
class DrawingPreviewPainter extends CustomPainter {
  /// Creates a drawing preview painter.
  ///
  /// Parameters:
  /// - [drawingData]: The drawing data to render, or null for empty canvas
  const DrawingPreviewPainter({
    this.drawingData,
  });

  /// The drawing data containing all strokes to preview.
  /// If null, renders an empty canvas.
  final DrawingData? drawingData;

  @override
  void paint(Canvas canvas, Size size) {
    // If no drawing data or empty, show empty state
    if (drawingData == null || drawingData!.strokes.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Draw all strokes with scaling to fit the preview size
    for (final stroke in drawingData!.strokes) {
      _drawStroke(canvas, size, stroke);
    }
  }

  /// Draws an empty state indicator for canvases with no strokes.
  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw a subtle centered icon-like shape
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final iconSize = size.width * 0.3;

    // Draw a simple brush icon
    canvas.drawCircle(
      Offset(centerX, centerY),
      iconSize / 2,
      paint,
    );
  }

  /// Draws a single stroke on the canvas with scaling.
  ///
  /// Scales the stroke from the original 2000x2000 canvas size to the
  /// preview size while maintaining the aspect ratio.
  void _drawStroke(Canvas canvas, Size size, DrawingStroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    // Calculate scaling factor from canvas size (2000x2000) to preview size
    const originalCanvasSize = 2000.0;
    final scaleX = size.width / originalCanvasSize;
    final scaleY = size.height / originalCanvasSize;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Create paint with the stroke's properties, scaling the stroke width
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Handle single point (draw a scaled dot)
    if (stroke.points.length == 1) {
      final scaledPoint = Offset(
        stroke.points.first.dx * scale,
        stroke.points.first.dy * scale,
      );
      canvas.drawCircle(
        scaledPoint,
        (stroke.strokeWidth * scale) / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Create path from scaled points
    final path = Path();
    final firstPoint = Offset(
      stroke.points.first.dx * scale,
      stroke.points.first.dy * scale,
    );
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final scaledPoint = Offset(
        stroke.points[i].dx * scale,
        stroke.points[i].dy * scale,
      );
      path.lineTo(scaledPoint.dx, scaledPoint.dy);
    }

    // Draw the path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPreviewPainter oldDelegate) {
    // Repaint if the drawing data changed
    return drawingData != oldDelegate.drawingData ||
        (drawingData?.version ?? 0) != (oldDelegate.drawingData?.version ?? 0);
  }
}
