import 'package:flutter/material.dart';
import '../../domain/entities/canvas_entity.dart';

/// Factory class for creating canvas painters based on canvas state
class CanvasPainterFactory {
  /// Private constructor to prevent instantiation
  CanvasPainterFactory._();

  /// Creates a custom painter for the given canvas state
  static CustomPainter createPainter(CanvasState state) {
    switch (state) {
      case CanvasState.geometric:
        return const GeometricCanvasPainter();
      case CanvasState.sketch:
        return const SketchCanvasPainter();
      case CanvasState.organic:
        return const OrganicCanvasPainter();
      case CanvasState.minimal:
        return const MinimalCanvasPainter();
      case CanvasState.empty:
        return const EmptyCanvasPainter();
    }
  }
}

/// Painter for geometric shapes canvas
class GeometricCanvasPainter extends CustomPainter {
  /// Creates a geometric canvas painter
  const GeometricCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Purple circle
    paint.color = Colors.deepPurple.withValues(alpha: 0.7);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      40,
      paint,
    );

    // Red squiggle line
    paint.color = Colors.red.withValues(alpha: 0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 6;
    paint.strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.9,
        size.width * 0.9,
        size.height * 0.7,
      );
    canvas.drawPath(path, paint);

    // Blue rectangle
    paint.color = Colors.blue.withValues(alpha: 0.6);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.6,
          size.height * 0.2,
          60,
          40,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    // Green star-like shape
    paint.color = Colors.green.withValues(alpha: 0.7);
    final starPath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..close();
    canvas.drawPath(starPath, paint);

    // Yellow dots
    paint.color = Colors.yellow.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.5), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.85), 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for sketch-style canvas
class SketchCanvasPainter extends CustomPainter {
  /// Creates a sketch canvas painter
  const SketchCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    // Dark gray sketchy circle
    paint.color = Colors.grey[800]!.withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.35),
      35,
      paint,
    );

    // Brown zigzag line
    paint.color = Colors.brown.withValues(alpha: 0.7);
    paint.strokeWidth = 4;
    final zigzag = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.6);
    canvas.drawPath(zigzag, paint);

    // Orange rectangle outline
    paint.color = Colors.orange.withValues(alpha: 0.7);
    paint.strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.6,
        80,
        50,
      ),
      paint,
    );

    // Teal curved line
    paint.color = Colors.teal.withValues(alpha: 0.7);
    paint.strokeWidth = 4;
    final curve = Path()
      ..moveTo(size.width * 0.7, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.5,
        size.width * 0.75,
        size.height * 0.7,
      );
    canvas.drawPath(curve, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for organic flowing shapes canvas
class OrganicCanvasPainter extends CustomPainter {
  /// Creates an organic canvas painter
  const OrganicCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Pink blob
    paint.color = Colors.pink.withValues(alpha: 0.5);
    final blob1 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.4,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.45,
        size.width * 0.2,
        size.height * 0.4,
      )
      ..close();
    canvas.drawPath(blob1, paint);

    // Cyan organic shape
    paint.color = Colors.cyan.withValues(alpha: 0.4);
    final blob2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.2)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.25,
        size.width * 0.8,
        size.height * 0.4,
        size.width * 0.7,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.45,
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.6,
        size.height * 0.2,
      )
      ..close();
    canvas.drawPath(blob2, paint);

    // Purple flowing line
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 8;
    paint.strokeCap = StrokeCap.round;
    paint.color = Colors.deepPurple.withValues(alpha: 0.5);
    final flow = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.5,
        size.width * 0.4,
        size.height * 0.8,
        size.width * 0.6,
        size.height * 0.7,
      )
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.65,
        size.width * 0.8,
        size.height * 0.75,
        size.width * 0.9,
        size.height * 0.8,
      );
    canvas.drawPath(flow, paint);

    // Lime green blob
    paint.style = PaintingStyle.fill;
    paint.color = Colors.lime.withValues(alpha: 0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.4),
        width: 60,
        height: 40,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for minimal canvas with few elements
class MinimalCanvasPainter extends CustomPainter {
  /// Creates a minimal canvas painter
  const MinimalCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Simple line
    paint.color = Colors.indigo.withValues(alpha: 0.6);
    paint.strokeWidth = 4;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.4),
      paint,
    );

    // Small circle
    paint.color = Colors.amber.withValues(alpha: 0.7);
    paint.strokeWidth = 3;
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.6),
      20,
      paint,
    );

    // Tiny dot (filled)
    paint.style = PaintingStyle.fill;
    paint.color = Colors.red.withValues(alpha: 0.8);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      6,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for empty canvas
class EmptyCanvasPainter extends CustomPainter {
  /// Creates an empty canvas painter
  const EmptyCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Intentionally empty - just a blank canvas
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
