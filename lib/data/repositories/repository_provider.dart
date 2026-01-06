import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/repositories/drawing_repository.dart';
import 'package:panci/data/repositories/firebase_drawing_repository.dart';

/// Provider for the drawing repository.
///
/// This provider creates and manages the [DrawingRepository] instance
/// used throughout the application. Following clean architecture and
/// dependency injection principles, this provider:
///
/// - Provides a single source of truth for the repository
/// - Allows easy testing by swapping implementations
/// - Manages the repository lifecycle
/// - Enables access from any widget via Riverpod
///
/// The repository is created once and cached for the lifetime of the app.
/// To override for testing, use ProviderScope with overrides:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     drawingRepositoryProvider.overrideWithValue(mockRepository),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// Usage in widgets:
/// ```dart
/// final repository = ref.read(drawingRepositoryProvider);
/// await repository.loadCanvas(canvasId);
/// ```
final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  // Create the Firebase implementation of the repository
  // In the future, this could be conditional based on environment,
  // feature flags, or A/B testing
  return FirebaseDrawingRepository();
});
