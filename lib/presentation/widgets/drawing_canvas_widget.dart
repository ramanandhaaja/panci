import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/presentation/providers/drawing_provider.dart';
import 'package:panci/presentation/widgets/canvas_painter.dart';

/// Widget that displays the interactive drawing canvas.
///
/// This widget handles user input (pan gestures) and renders the drawing
/// using a CustomPainter. It transforms screen coordinates to canvas
/// coordinates to account for the FittedBox scaling.
///
/// The canvas is a fixed 2000x2000 logical pixel canvas that scales to
/// fit the available screen space.
class DrawingCanvasWidget extends ConsumerStatefulWidget {
  /// Creates a drawing canvas widget.
  ///
  /// Parameters:
  /// - [canvasId]: The ID of the canvas to draw on
  /// - [selectedColor]: The color to use for new strokes
  /// - [selectedBrushSize]: The brush size to use for new strokes
  /// - [repaintBoundaryKey]: Optional GlobalKey for the RepaintBoundary
  ///   (used for exporting the canvas to an image)
  const DrawingCanvasWidget({
    super.key,
    required this.canvasId,
    required this.selectedColor,
    required this.selectedBrushSize,
    this.repaintBoundaryKey,
  });

  /// The ID of the canvas to draw on.
  final String canvasId;

  /// The color to use for drawing new strokes.
  final Color selectedColor;

  /// The brush size to use for drawing new strokes.
  final double selectedBrushSize;

  /// Optional GlobalKey for the RepaintBoundary.
  ///
  /// If provided, this key can be used to capture the canvas as an image
  /// for export functionality.
  final GlobalKey? repaintBoundaryKey;

  /// The logical size of the canvas (in logical pixels).
  ///
  /// The canvas will scale to fit the available space while maintaining
  /// this aspect ratio.
  static const double canvasSize = 2000.0;

  @override
  ConsumerState<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends ConsumerState<DrawingCanvasWidget> {
  /// Global key for the RepaintBoundary (for export functionality).
  /// Uses the provided key from widget, or creates a local one.
  late final GlobalKey _repaintBoundaryKey;

  /// Global key for the canvas container to get its size for coordinate transformation.
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _repaintBoundaryKey = widget.repaintBoundaryKey ?? GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the drawing state for this canvas
    final drawingState = ref.watch(drawingProvider(widget.canvasId));

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: DrawingCanvasWidget.canvasSize,
          height: DrawingCanvasWidget.canvasSize,
          child: GestureDetector(
            key: _canvasKey,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onPanCancel: _handlePanCancel,
            child: Container(
              width: DrawingCanvasWidget.canvasSize,
              height: DrawingCanvasWidget.canvasSize,
              color: Colors.white,
              child: CustomPaint(
                painter: CanvasPainter(
                  drawingData: drawingState.currentDrawing,
                  currentStroke: drawingState.currentStroke,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the start of a pan gesture (user touches down).
  void _handlePanStart(DragStartDetails details) {
    // Convert screen coordinates to canvas coordinates
    final canvasPoint = _screenToCanvas(details.localPosition);

    if (canvasPoint != null) {
      ref.read(drawingProvider(widget.canvasId).notifier).startStroke(
            canvasPoint,
            widget.selectedColor,
            widget.selectedBrushSize,
          );
    }
  }

  /// Handles pan gesture updates (user moves while touching).
  void _handlePanUpdate(DragUpdateDetails details) {
    // Convert screen coordinates to canvas coordinates
    final canvasPoint = _screenToCanvas(details.localPosition);

    if (canvasPoint != null) {
      ref.read(drawingProvider(widget.canvasId).notifier).addPoint(canvasPoint);
    }
  }

  /// Handles the end of a pan gesture (user lifts finger).
  void _handlePanEnd(DragEndDetails details) {
    ref.read(drawingProvider(widget.canvasId).notifier).endStroke();
  }

  /// Handles pan gesture cancellation.
  void _handlePanCancel() {
    ref.read(drawingProvider(widget.canvasId).notifier).cancelCurrentStroke();
  }

  /// Converts screen coordinates to canvas coordinates.
  ///
  /// Takes into account the FittedBox scaling and returns coordinates
  /// in the logical canvas space (0-2000).
  ///
  /// Returns null if the conversion cannot be performed (e.g., widget
  /// not yet laid out).
  Offset? _screenToCanvas(Offset screenPosition) {
    // The GestureDetector is inside the SizedBox with canvasSize dimensions,
    // and the FittedBox scales it to fit. However, the localPosition from
    // GestureDetector is already in the coordinate space of the SizedBox
    // (i.e., canvas coordinates), so no transformation is needed.
    //
    // This is because GestureDetector receives events in its own coordinate
    // space, which is the canvas space due to being inside the SizedBox.

    return screenPosition;
  }
}
