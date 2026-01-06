import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/data/repositories/repository_provider.dart';

/// Provider that fetches drawing data for a specific canvas for preview purposes.
///
/// This is a FutureProvider that loads the canvas data once for displaying
/// in preview cards on the home screen. It uses the .family modifier to
/// create a separate instance for each canvas ID.
///
/// Unlike the drawingProvider which maintains real-time state and subscriptions,
/// this provider simply loads the data once for display purposes.
///
/// Usage:
/// ```dart
/// final drawingDataAsync = ref.watch(canvasPreviewProvider(canvasId));
///
/// drawingDataAsync.when(
///   data: (drawingData) => DrawingPreviewPainter(drawingData: drawingData),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(),
/// );
/// ```
final canvasPreviewProvider = FutureProvider.family<DrawingData, String>(
  (ref, canvasId) async {
    final repository = ref.watch(drawingRepositoryProvider);
    return repository.loadCanvas(canvasId);
  },
);

/// Provider that watches a canvas for real-time preview updates.
///
/// This is a StreamProvider that subscribes to canvas changes and updates
/// the preview in real-time. Useful for showing live updates on the home screen.
///
/// Usage:
/// ```dart
/// final drawingDataAsync = ref.watch(canvasPreviewStreamProvider(canvasId));
///
/// drawingDataAsync.when(
///   data: (drawingData) => DrawingPreviewPainter(drawingData: drawingData),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(),
/// );
/// ```
final canvasPreviewStreamProvider = StreamProvider.family<DrawingData, String>(
  (ref, canvasId) {
    final repository = ref.watch(drawingRepositoryProvider);
    return repository.watchCanvas(canvasId);
  },
);
