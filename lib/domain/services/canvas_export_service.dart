import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

/// Service for exporting canvas to PNG images.
///
/// This domain service handles the conversion of the Flutter canvas
/// (via RepaintBoundary) to a PNG image with compression. It follows
/// clean architecture principles by having no external dependencies
/// and operating purely on Flutter's rendering layer.
///
/// Features:
/// - Captures RepaintBoundary at specified resolution
/// - Converts to PNG format
/// - Compresses images to target file size (<500KB)
/// - Maintains high visual quality
/// - Handles errors gracefully
///
/// Usage:
/// ```dart
/// final exportService = CanvasExportService();
/// final pngBytes = await exportService.exportToPng(repaintBoundaryKey);
/// ```
class CanvasExportService {
  /// Creates a canvas export service.
  const CanvasExportService();

  /// Target image dimensions (2000x2000 pixels for high quality).
  static const double targetSize = 2000.0;

  /// Target file size in bytes (500KB).
  static const int targetFileSizeBytes = 500 * 1024;

  /// Exports the canvas to a PNG image.
  ///
  /// This method captures the RepaintBoundary identified by [repaintBoundaryKey]
  /// and converts it to a PNG image with compression.
  ///
  /// Parameters:
  /// - [repaintBoundaryKey]: GlobalKey for the RepaintBoundary to capture
  /// - [pixelRatio]: Pixel ratio for rendering (default: 1.0 for exact size)
  ///
  /// Returns:
  /// - PNG image data as Uint8List
  ///
  /// Throws:
  /// - [Exception] if the key is not attached to a RepaintBoundary
  /// - [Exception] if image capture or conversion fails
  Future<Uint8List> exportToPng(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 1.0,
  }) async {
    try {
      // Get the RepaintBoundary's render object
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception(
          'RepaintBoundary not found. Ensure the key is attached to a RepaintBoundary widget.',
        );
      }

      // Capture the boundary as an image
      debugPrint('Capturing canvas at ${targetSize}x$targetSize with pixelRatio $pixelRatio');
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      debugPrint('Canvas captured: ${image.width}x${image.height} pixels');

      // Convert to PNG byte data
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert image to PNG format');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final originalSize = pngBytes.length;

      debugPrint(
        'PNG generated: ${(originalSize / 1024).toStringAsFixed(2)} KB',
      );

      // Compress if needed to meet target file size
      if (originalSize > targetFileSizeBytes) {
        debugPrint('Compressing image to meet target size...');
        final compressedBytes = await _compressImage(pngBytes);
        final compressedSize = compressedBytes.length;

        debugPrint(
          'PNG compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB '
          '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% reduction)',
        );

        return compressedBytes;
      }

      debugPrint('No compression needed, image already under target size');
      return pngBytes;
    } catch (e, stackTrace) {
      debugPrint('Error exporting canvas to PNG: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Compresses a PNG image to meet the target file size.
  ///
  /// Uses progressive quality reduction to achieve the target size
  /// while maintaining acceptable visual quality.
  ///
  /// Parameters:
  /// - [pngBytes]: Original PNG image data
  ///
  /// Returns:
  /// - Compressed PNG image data
  Future<Uint8List> _compressImage(Uint8List pngBytes) async {
    try {
      // Decode the PNG image
      final image = img.decodeImage(pngBytes);

      if (image == null) {
        throw Exception('Failed to decode PNG image for compression');
      }

      // Try compression with level 9 (maximum)
      final compressed = img.encodePng(image, level: 9);
      final compressedBytes = Uint8List.fromList(compressed);

      debugPrint(
        'Compression attempt (level 9): '
        '${(compressedBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      if (compressedBytes.length <= targetFileSizeBytes) {
        return compressedBytes;
      }

      // If still too large, resize the image
      debugPrint('Image still too large, resizing...');
      final resized = img.copyResize(
        image,
        width: (targetSize * 0.8).toInt(),
        height: (targetSize * 0.8).toInt(),
        interpolation: img.Interpolation.average,
      );

      final resizedCompressed = img.encodePng(resized, level: 9);
      final resizedBytes = Uint8List.fromList(resizedCompressed);

      debugPrint(
        'Resized and compressed: ${(resizedBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      return resizedBytes;
    } catch (e, stackTrace) {
      debugPrint('Error compressing image: $e');
      debugPrint('Stack trace: $stackTrace');

      // If compression fails, return original
      debugPrint('Returning original image due to compression error');
      return pngBytes;
    }
  }

  /// Estimates the compressed size without actually compressing.
  ///
  /// This is a utility method for UI purposes (e.g., showing estimated
  /// export size before actually exporting).
  ///
  /// Returns approximate file size in bytes.
  int estimateFileSize(int width, int height, int strokeCount) {
    // Very rough estimation: base size + per-stroke overhead
    const baseSize = 50 * 1024; // 50KB base
    const perStrokeSize = 200; // ~200 bytes per stroke

    final estimated = baseSize + (strokeCount * perStrokeSize);

    // Apply compression factor (assuming ~60% of uncompressed)
    return (estimated * 0.6).toInt();
  }
}
