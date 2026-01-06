import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Repository interface for managing drawing data persistence.
///
/// This abstract class defines the contract for storing and retrieving
/// drawing data. Following clean architecture principles, this interface
/// is defined in the domain layer and is implemented in the data layer.
///
/// The repository pattern provides:
/// - Abstraction over data sources (Firestore, local storage, etc.)
/// - Single source of truth for drawing data
/// - Separation of concerns between business logic and data access
/// - Easy testability through mocking
///
/// Implementations should handle:
/// - Network errors and offline scenarios
/// - Data validation and sanitization
/// - Concurrent modifications and conflict resolution
/// - Proper error handling and logging
abstract class DrawingRepository {
  /// Loads canvas data from storage.
  ///
  /// Fetches the complete drawing data for the specified canvas,
  /// including all strokes and metadata.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  ///
  /// Returns:
  /// - [DrawingData] containing all strokes and metadata
  /// - If the canvas doesn't exist, returns an empty [DrawingData]
  ///
  /// Throws:
  /// - Exception if there's a critical error loading the data
  ///   (network issues, permission errors, etc.)
  ///
  /// Example:
  /// ```dart
  /// final data = await repository.loadCanvas('canvas-123');
  /// print('Loaded ${data.strokeCount} strokes');
  /// ```
  Future<DrawingData> loadCanvas(String canvasId);

  /// Saves a stroke to the canvas.
  ///
  /// Adds a new stroke to the specified canvas in persistent storage.
  /// The operation should be atomic to prevent data corruption.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  /// - [stroke]: The stroke to add to the canvas
  ///
  /// Returns:
  /// - Completes when the stroke has been successfully saved
  ///
  /// Throws:
  /// - Exception if the save operation fails
  ///   (network issues, storage quota exceeded, etc.)
  ///
  /// Example:
  /// ```dart
  /// await repository.saveStroke('canvas-123', newStroke);
  /// ```
  Future<void> saveStroke(String canvasId, DrawingStroke stroke);

  /// Removes a stroke from the canvas.
  ///
  /// Deletes the stroke with the specified ID from the canvas.
  /// If the stroke doesn't exist, the operation should complete
  /// successfully without error.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  /// - [strokeId]: The unique identifier for the stroke to remove
  ///
  /// Returns:
  /// - Completes when the stroke has been successfully removed
  ///
  /// Throws:
  /// - Exception if the remove operation fails
  ///   (network issues, permission errors, etc.)
  ///
  /// Example:
  /// ```dart
  /// await repository.removeStroke('canvas-123', 'stroke-456');
  /// ```
  Future<void> removeStroke(String canvasId, String strokeId);

  /// Watches canvas for real-time updates.
  ///
  /// Returns a stream that emits the latest drawing data whenever
  /// the canvas is modified. This enables real-time collaboration
  /// where multiple users can see each other's changes.
  ///
  /// The stream:
  /// - Emits initial data immediately when subscribed
  /// - Emits new data whenever the canvas is modified
  /// - Continues until the stream is cancelled
  /// - Should handle errors gracefully (emit error, then continue)
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  ///
  /// Returns:
  /// - Stream of [DrawingData] with the latest canvas state
  ///
  /// Example:
  /// ```dart
  /// final subscription = repository.watchCanvas('canvas-123').listen(
  ///   (data) => print('Canvas updated: ${data.strokeCount} strokes'),
  ///   onError: (error) => print('Watch error: $error'),
  /// );
  ///
  /// // Later, cancel the subscription
  /// await subscription.cancel();
  /// ```
  Stream<DrawingData> watchCanvas(String canvasId);

  /// Clears all strokes from a canvas.
  ///
  /// Removes all strokes from the specified canvas, effectively
  /// resetting it to an empty state. This operation should be
  /// atomic and irreversible.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  ///
  /// Returns:
  /// - Completes when all strokes have been successfully cleared
  ///
  /// Throws:
  /// - Exception if the clear operation fails
  ///   (network issues, permission errors, etc.)
  ///
  /// Example:
  /// ```dart
  /// await repository.clearCanvas('canvas-123');
  /// ```
  Future<void> clearCanvas(String canvasId);
}
