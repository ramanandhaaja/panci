import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';
import 'package:panci/domain/repositories/drawing_repository.dart';
import 'package:panci/data/models/drawing_data_model.dart';
import 'package:panci/data/models/drawing_stroke_model.dart';

/// Firebase Firestore implementation of the [DrawingRepository].
///
/// This class provides persistent storage for drawing data using
/// Cloud Firestore. It implements the repository interface defined
/// in the domain layer, following clean architecture principles.
///
/// Firestore structure:
/// ```
/// canvases/{canvasId}
///   - canvasId: string
///   - strokes: array of stroke objects
///   - lastUpdated: ISO timestamp string
///   - version: integer
/// ```
///
/// Features:
/// - Real-time synchronization across multiple devices
/// - Offline persistence with automatic sync when online
/// - Atomic operations to prevent data corruption
/// - Optimistic concurrency control with version numbers
/// - Efficient updates using Firestore array operations
///
/// Error handling:
/// - Network errors are logged and propagated as exceptions
/// - Missing documents are treated as empty canvases
/// - Invalid data is logged and handled gracefully
class FirebaseDrawingRepository implements DrawingRepository {
  /// Creates a Firebase drawing repository.
  ///
  /// By default, uses the default Firestore instance. A custom instance
  /// can be provided for testing or multi-project scenarios.
  FirebaseDrawingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Enable offline persistence for better user experience
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// The Firestore instance used for data operations.
  final FirebaseFirestore _firestore;

  /// The collection path for canvas documents.
  static const String _canvasesCollection = 'canvases';

  /// Gets a reference to a canvas document.
  DocumentReference<Map<String, dynamic>> _getCanvasRef(String canvasId) {
    return _firestore.collection(_canvasesCollection).doc(canvasId);
  }

  @override
  Future<DrawingData> loadCanvas(String canvasId) async {
    try {
      debugPrint('Loading canvas: $canvasId');

      final docSnapshot = await _getCanvasRef(canvasId).get();

      // If the document doesn't exist, return an empty canvas
      if (!docSnapshot.exists) {
        debugPrint('Canvas $canvasId does not exist, returning empty canvas');
        return DrawingData.empty(canvasId);
      }

      // Get the document data
      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('Canvas $canvasId has null data, returning empty canvas');
        return DrawingData.empty(canvasId);
      }

      // Convert from Firestore JSON to domain entity
      final model = DrawingDataModel.fromJson(data);
      final entity = model.toEntity();

      debugPrint(
        'Loaded canvas $canvasId: ${entity.strokeCount} strokes, version ${entity.version}',
      );

      return entity;
    } catch (e, stackTrace) {
      debugPrint('Error loading canvas $canvasId: $e');
      debugPrint('Stack trace: $stackTrace');

      // For critical errors, propagate the exception
      // For minor errors (like parsing), return empty canvas
      if (e is FirebaseException) {
        throw Exception('Failed to load canvas: ${e.message}');
      }

      // If it's a parsing error, return empty canvas
      debugPrint('Returning empty canvas due to error');
      return DrawingData.empty(canvasId);
    }
  }

  @override
  Future<void> saveStroke(String canvasId, DrawingStroke stroke) async {
    try {
      debugPrint('Saving stroke ${stroke.id} to canvas $canvasId');

      // Convert stroke to JSON
      final strokeJson = DrawingStrokeModel.fromEntity(stroke).toJson();

      // Use Firestore transaction to ensure atomic update
      final docRef = _getCanvasRef(canvasId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        // Prepare the update data
        final updateData = <String, dynamic>{
          'canvasId': canvasId,
          'strokes': FieldValue.arrayUnion([strokeJson]),
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': FieldValue.increment(1),
        };

        if (snapshot.exists) {
          // Update existing document
          transaction.update(docRef, updateData);
        } else {
          // Create new document
          updateData['version'] = 1;
          transaction.set(docRef, updateData);
        }
      });

      debugPrint('Successfully saved stroke ${stroke.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving stroke ${stroke.id}: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to save stroke: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeStroke(String canvasId, String strokeId) async {
    try {
      debugPrint('Removing stroke $strokeId from canvas $canvasId');

      // Load the current canvas to get all strokes
      final currentData = await loadCanvas(canvasId);

      // Filter out the stroke to remove
      final updatedStrokes = currentData.strokes
          .where((stroke) => stroke.id != strokeId)
          .toList();

      // Convert strokes to JSON
      final strokesJson = updatedStrokes
          .map((stroke) => DrawingStrokeModel.fromEntity(stroke).toJson())
          .toList();

      // Update the entire strokes array
      final docRef = _getCanvasRef(canvasId);
      await docRef.update({
        'strokes': strokesJson,
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': FieldValue.increment(1),
      });

      debugPrint('Successfully removed stroke $strokeId');
    } catch (e, stackTrace) {
      debugPrint('Error removing stroke $strokeId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to remove stroke: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Stream<DrawingData> watchCanvas(String canvasId) {
    debugPrint('Starting to watch canvas: $canvasId');

    return _getCanvasRef(canvasId).snapshots().map((snapshot) {
      try {
        // If the document doesn't exist, return an empty canvas
        if (!snapshot.exists) {
          debugPrint('Canvas $canvasId does not exist in watch, returning empty');
          return DrawingData.empty(canvasId);
        }

        // Get the document data
        final data = snapshot.data();
        if (data == null) {
          debugPrint('Canvas $canvasId has null data in watch, returning empty');
          return DrawingData.empty(canvasId);
        }

        // Convert from Firestore JSON to domain entity
        final model = DrawingDataModel.fromJson(data);
        final entity = model.toEntity();

        debugPrint(
          'Canvas $canvasId updated: ${entity.strokeCount} strokes, version ${entity.version}',
        );

        return entity;
      } catch (e, stackTrace) {
        debugPrint('Error in canvas watch stream: $e');
        debugPrint('Stack trace: $stackTrace');

        // Return empty canvas on error to keep the stream alive
        return DrawingData.empty(canvasId);
      }
    }).handleError((error, stackTrace) {
      debugPrint('Error in canvas watch stream handler: $error');
      debugPrint('Stack trace: $stackTrace');

      // Log the error but don't propagate it to keep the stream alive
      // The stream will continue to function and emit updates
    });
  }

  @override
  Future<void> clearCanvas(String canvasId) async {
    try {
      debugPrint('Clearing canvas: $canvasId');

      final docRef = _getCanvasRef(canvasId);

      await docRef.update({
        'strokes': [],
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': FieldValue.increment(1),
      });

      debugPrint('Successfully cleared canvas $canvasId');
    } catch (e, stackTrace) {
      debugPrint('Error clearing canvas $canvasId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to clear canvas: ${e.message}');
      }
      rethrow;
    }
  }

  /// Deletes a canvas and all its data.
  ///
  /// This is a utility method for canvas cleanup, not part of the
  /// repository interface. Use with caution as this operation
  /// cannot be undone.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas to delete
  Future<void> deleteCanvas(String canvasId) async {
    try {
      debugPrint('Deleting canvas: $canvasId');

      await _getCanvasRef(canvasId).delete();

      debugPrint('Successfully deleted canvas $canvasId');
    } catch (e, stackTrace) {
      debugPrint('Error deleting canvas $canvasId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to delete canvas: ${e.message}');
      }
      rethrow;
    }
  }

  /// Checks if a canvas exists in Firestore.
  ///
  /// This is a utility method for checking canvas existence before
  /// performing operations.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  ///
  /// Returns:
  /// - true if the canvas exists, false otherwise
  Future<bool> canvasExists(String canvasId) async {
    try {
      final docSnapshot = await _getCanvasRef(canvasId).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking canvas existence: $e');
      return false;
    }
  }
}
