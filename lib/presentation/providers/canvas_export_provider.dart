import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/services/canvas_export_service.dart';
import 'package:panci/data/repositories/firebase_drawing_repository.dart';
import 'package:panci/data/repositories/repository_provider.dart';

/// Represents the state of a canvas export operation.
@immutable
class CanvasExportState {
  /// Creates a canvas export state.
  const CanvasExportState({
    this.isExporting = false,
    this.progress = 0.0,
    this.status = '',
    this.error,
    this.imageUrl,
  });

  /// Whether an export is currently in progress.
  final bool isExporting;

  /// Export progress from 0.0 to 1.0.
  final double progress;

  /// Current status message (e.g., "Rendering image...", "Uploading...").
  final String status;

  /// Error message if export failed.
  final String? error;

  /// Download URL of the exported image.
  final String? imageUrl;

  /// Creates a copy of this state with the given fields replaced.
  CanvasExportState copyWith({
    bool? isExporting,
    double? progress,
    String? status,
    String? error,
    String? imageUrl,
    bool clearError = false,
  }) {
    return CanvasExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasExportState &&
        other.isExporting == isExporting &&
        other.progress == progress &&
        other.status == status &&
        other.error == error &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      isExporting,
      progress,
      status,
      error,
      imageUrl,
    );
  }

  @override
  String toString() {
    return 'CanvasExportState(isExporting: $isExporting, progress: $progress, '
        'status: $status, error: $error, imageUrl: $imageUrl)';
  }
}

/// StateNotifier that manages canvas export operations.
///
/// This notifier orchestrates the complete export flow:
/// 1. Captures the canvas as PNG using RepaintBoundary
/// 2. Compresses the image if needed
/// 3. Uploads to Firebase Storage
/// 4. Updates Firestore with the image URL
///
/// It follows clean architecture by:
/// - Using domain services (CanvasExportService)
/// - Using data layer repositories (FirebaseDrawingRepository)
/// - Managing presentation state (progress, status, errors)
/// - Providing clear status updates for UI feedback
class CanvasExportNotifier extends StateNotifier<CanvasExportState> {
  /// Creates a canvas export notifier.
  CanvasExportNotifier(
    this._canvasId,
    this._exportService,
    this._repository,
  ) : super(const CanvasExportState());

  /// The ID of the canvas being exported.
  final String _canvasId;

  /// The export service for PNG generation.
  final CanvasExportService _exportService;

  /// The repository for uploading and updating canvas data.
  final FirebaseDrawingRepository _repository;

  /// Exports the canvas to PNG and uploads to Firebase Storage.
  ///
  /// This method performs the complete export flow:
  /// 1. Captures RepaintBoundary as PNG
  /// 2. Compresses image if needed
  /// 3. Uploads to Firebase Storage
  /// 4. Updates Firestore with image URL
  ///
  /// Parameters:
  /// - [repaintBoundaryKey]: GlobalKey for the RepaintBoundary to capture
  ///
  /// Returns:
  /// - The download URL of the uploaded image
  ///
  /// Throws:
  /// - Exception if any step of the export process fails
  Future<String?> exportCanvas(GlobalKey repaintBoundaryKey) async {
    if (state.isExporting) {
      debugPrint('Export already in progress, skipping');
      return null;
    }

    try {
      debugPrint('Starting canvas export for $_canvasId');

      // Start export
      state = state.copyWith(
        isExporting: true,
        progress: 0.0,
        status: 'Rendering image...',
        clearError: true,
      );

      // Step 1: Capture and convert to PNG (0% - 40%)
      final Uint8List pngBytes = await _exportService.exportToPng(
        repaintBoundaryKey,
        pixelRatio: 1.0,
      );

      state = state.copyWith(
        progress: 0.4,
        status: 'Uploading to cloud...',
      );

      // Step 2: Upload to Firebase Storage (40% - 80%)
      final String downloadUrl = await _repository.uploadCanvasImage(
        _canvasId,
        pngBytes,
      );

      state = state.copyWith(
        progress: 0.8,
        status: 'Finalizing...',
      );

      // Step 3: Update Firestore with image URL (80% - 100%)
      await _repository.updateCanvasImage(
        _canvasId,
        downloadUrl,
        DateTime.now(),
      );

      // Export complete
      state = state.copyWith(
        isExporting: false,
        progress: 1.0,
        status: 'Export complete',
        imageUrl: downloadUrl,
      );

      debugPrint('Canvas export completed successfully: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('Error exporting canvas: $e');
      debugPrint('Stack trace: $stackTrace');

      state = state.copyWith(
        isExporting: false,
        progress: 0.0,
        status: '',
        error: 'Failed to export canvas: ${e.toString()}',
      );

      rethrow;
    }
  }

  /// Clears the error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for the canvas export service.
final canvasExportServiceProvider = Provider<CanvasExportService>((ref) {
  return const CanvasExportService();
});

/// Provider for canvas export state management.
///
/// Uses the .family modifier to create a separate export state instance
/// for each canvas ID.
///
/// Usage:
/// ```dart
/// // Watch the export state
/// final exportState = ref.watch(canvasExportProvider(canvasId));
///
/// // Export the canvas
/// await ref.read(canvasExportProvider(canvasId).notifier).exportCanvas(key);
///
/// // Schedule auto-export
/// ref.read(canvasExportProvider(canvasId).notifier).scheduleAutoExport(key);
/// ```
final canvasExportProvider = StateNotifierProvider.family<
    CanvasExportNotifier,
    CanvasExportState,
    String>(
  (ref, canvasId) {
    final exportService = ref.watch(canvasExportServiceProvider);
    final repository = ref.watch(drawingRepositoryProvider)
        as FirebaseDrawingRepository;

    return CanvasExportNotifier(
      canvasId,
      exportService,
      repository,
    );
  },
);
