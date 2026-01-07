import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  FirebaseDrawingRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance {
    // Enable offline persistence for better user experience
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// The Firestore instance used for data operations.
  final FirebaseFirestore _firestore;

  /// The Firebase Storage instance used for image uploads.
  final FirebaseStorage _storage;

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

      // If the document doesn't exist, throw an exception
      // This is different from the previous behavior to enforce proper canvas creation
      if (!docSnapshot.exists) {
        debugPrint('Canvas $canvasId does not exist');
        throw Exception(
          'Canvas $canvasId not found. '
          'Canvas must be created with an owner before loading.',
        );
      }

      // Get the document data
      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('Canvas $canvasId has null data');
        throw Exception(
          'Canvas $canvasId has null data. The document exists but contains no data.',
        );
      }

      // Convert from Firestore JSON to domain entity
      final model = DrawingDataModel.fromJson(data);
      final entity = model.toEntity();

      debugPrint(
        'Loaded canvas $canvasId: ${entity.strokeCount} strokes, version ${entity.version}, '
        'owner: ${entity.ownerId}, teamMembers: ${entity.teamMembers.length}, '
        'isPrivate: ${entity.isPrivate}',
      );

      return entity;
    } catch (e, stackTrace) {
      debugPrint('Error loading canvas $canvasId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to load canvas: ${e.message}');
      }
      rethrow;
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

        if (snapshot.exists) {
          // Update existing document
          final updateData = <String, dynamic>{
            'strokes': FieldValue.arrayUnion([strokeJson]),
            'lastUpdated': DateTime.now().toIso8601String(),
            'version': FieldValue.increment(1),
          };
          transaction.update(docRef, updateData);
        } else {
          // Canvas doesn't exist - this should not happen
          // The canvas must be created first with ownership information
          throw Exception(
            'Canvas $canvasId does not exist. '
            'Canvas must be created with createCanvas() before adding strokes.',
          );
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
        // If the document doesn't exist, throw an error
        // This is consistent with the loadCanvas behavior
        if (!snapshot.exists) {
          debugPrint('Canvas $canvasId does not exist in watch');
          throw Exception('Canvas $canvasId not found in watch stream');
        }

        // Get the document data
        final data = snapshot.data();
        if (data == null) {
          debugPrint('Canvas $canvasId has null data in watch');
          throw Exception('Canvas $canvasId has null data in watch stream');
        }

        // Convert from Firestore JSON to domain entity
        final model = DrawingDataModel.fromJson(data);
        final entity = model.toEntity();

        debugPrint(
          'Canvas $canvasId updated: ${entity.strokeCount} strokes, version ${entity.version}, '
          'owner: ${entity.ownerId}, teamMembers: ${entity.teamMembers.length}',
        );

        return entity;
      } catch (e, stackTrace) {
        debugPrint('Error in canvas watch stream: $e');
        debugPrint('Stack trace: $stackTrace');

        // Rethrow to propagate the error through the stream
        rethrow;
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

  @override
  Future<void> updateCanvasImage(
    String canvasId,
    String imageUrl,
    DateTime lastExported,
  ) async {
    try {
      debugPrint('Updating canvas $canvasId with image URL: $imageUrl');

      final docRef = _getCanvasRef(canvasId);

      await docRef.update({
        'imageUrl': imageUrl,
        'lastExported': lastExported.toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully updated canvas $canvasId with image metadata');
    } catch (e, stackTrace) {
      debugPrint('Error updating canvas image metadata: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to update canvas image: ${e.message}');
      }
      rethrow;
    }
  }

  /// Uploads a PNG image to Firebase Storage.
  ///
  /// Uploads the canvas image to the path: canvases/{canvasId}/latest.png
  /// and returns the download URL.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  /// - [pngBytes]: The PNG image data to upload
  ///
  /// Returns:
  /// - The download URL for the uploaded image
  ///
  /// Throws:
  /// - Exception if the upload fails
  Future<String> uploadCanvasImage(
    String canvasId,
    Uint8List pngBytes,
  ) async {
    try {
      debugPrint(
        'Uploading canvas image for $canvasId (${(pngBytes.length / 1024).toStringAsFixed(2)} KB)',
      );

      // Create storage reference
      final storageRef = _storage.ref().child('canvases/$canvasId/latest.png');

      // Set metadata for the image
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'canvasId': canvasId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the image
      final uploadTask = storageRef.putData(pngBytes, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Successfully uploaded canvas image: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('Error uploading canvas image: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to upload canvas image: ${e.message}');
      }
      rethrow;
    }
  }

  /// Deletes the canvas image from Firebase Storage.
  ///
  /// This is a utility method for cleaning up canvas images.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  Future<void> deleteCanvasImage(String canvasId) async {
    try {
      debugPrint('Deleting canvas image for $canvasId');

      final storageRef = _storage.ref().child('canvases/$canvasId/latest.png');
      await storageRef.delete();

      debugPrint('Successfully deleted canvas image');
    } catch (e) {
      debugPrint('Error deleting canvas image: $e');
      // Don't throw - image might not exist, which is okay
    }
  }

  @override
  Future<bool> checkCanvasAccess(String canvasId, String userId) async {
    try {
      debugPrint('Checking canvas access: canvas=$canvasId, user=$userId');

      // Load the canvas document
      final docSnapshot = await _getCanvasRef(canvasId).get();

      if (!docSnapshot.exists) {
        debugPrint('Canvas $canvasId does not exist, access denied');
        return false;
      }

      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('Canvas $canvasId has null data, access denied');
        return false;
      }

      // Parse the canvas data
      final model = DrawingDataModel.fromJson(data);
      final entity = model.toEntity();

      // Check access using the entity's hasAccess method
      final hasAccess = entity.hasAccess(userId);

      debugPrint(
        'Canvas access check result: $hasAccess '
        '(owner: ${entity.ownerId}, isPrivate: ${entity.isPrivate}, '
        'teamMembers: ${entity.teamMembers.length})',
      );

      return hasAccess;
    } catch (e, stackTrace) {
      debugPrint('Error checking canvas access: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to check canvas access: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> addTeamMember(String canvasId, String userId) async {
    try {
      debugPrint('Adding team member: canvas=$canvasId, user=$userId');

      // Check if the user exists first (optional but recommended)
      // This would require a UserRepository instance, so we'll skip for now
      // and assume the calling code has verified the user exists

      // Use Firestore arrayUnion to add the userId to teamMembers
      // This is idempotent - adding an existing member does nothing
      final docRef = _getCanvasRef(canvasId);

      await docRef.update({
        'teamMembers': FieldValue.arrayUnion([userId]),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully added team member: user=$userId to canvas=$canvasId');
    } catch (e, stackTrace) {
      debugPrint('Error adding team member: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        // Check if the error is due to missing document
        if (e.code == 'not-found') {
          throw Exception(
            'Canvas $canvasId not found. Cannot add team member to non-existent canvas.',
          );
        }
        throw Exception('Failed to add team member: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeTeamMember(String canvasId, String userId) async {
    try {
      debugPrint('Removing team member: canvas=$canvasId, user=$userId');

      // Use Firestore arrayRemove to remove the userId from teamMembers
      // This is idempotent - removing a non-existent member does nothing
      final docRef = _getCanvasRef(canvasId);

      await docRef.update({
        'teamMembers': FieldValue.arrayRemove([userId]),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully removed team member: user=$userId from canvas=$canvasId');
    } catch (e, stackTrace) {
      debugPrint('Error removing team member: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        // Check if the error is due to missing document
        if (e.code == 'not-found') {
          throw Exception(
            'Canvas $canvasId not found. Cannot remove team member from non-existent canvas.',
          );
        }
        throw Exception('Failed to remove team member: ${e.message}');
      }
      rethrow;
    }
  }

  /// Creates a new canvas with ownership information.
  ///
  /// This is a utility method for creating a canvas document with the
  /// initial owner. It should be called when a user creates a new canvas.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the new canvas
  /// - [ownerId]: The Firebase Auth UID of the canvas creator
  /// - [isPrivate]: Whether the canvas is private (default: true)
  ///
  /// Returns:
  /// - The newly created [DrawingData] entity
  ///
  /// Throws:
  /// - Exception if the canvas already exists
  /// - Exception if there's a network or permission error
  Future<DrawingData> createCanvas({
    required String canvasId,
    required String ownerId,
    bool isPrivate = true,
  }) async {
    try {
      debugPrint(
        'Creating canvas: $canvasId for owner: $ownerId (isPrivate: $isPrivate)',
      );

      // Check if canvas already exists
      final docRef = _getCanvasRef(canvasId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        debugPrint('Canvas $canvasId already exists');
        throw Exception(
          'Canvas $canvasId already exists. Use loadCanvas() to load existing canvas.',
        );
      }

      // Create empty canvas entity
      final entity = DrawingData.empty(
        canvasId,
        ownerId: ownerId,
        isPrivate: isPrivate,
      );

      // Convert to model and save to Firestore
      final model = DrawingDataModel.fromEntity(entity);
      await docRef.set(model.toJson());

      debugPrint('Successfully created canvas: $canvasId for owner: $ownerId');

      return entity;
    } catch (e, stackTrace) {
      debugPrint('Error creating canvas $canvasId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to create canvas: ${e.message}');
      }
      rethrow;
    }
  }

  /// Updates the canvas privacy setting.
  ///
  /// This utility method allows changing whether a canvas is private or public.
  /// Only the canvas owner should be allowed to change this setting.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  /// - [isPrivate]: Whether the canvas should be private
  Future<void> updateCanvasPrivacy({
    required String canvasId,
    required bool isPrivate,
  }) async {
    try {
      debugPrint('Updating canvas privacy: $canvasId to isPrivate=$isPrivate');

      final docRef = _getCanvasRef(canvasId);

      await docRef.update({
        'isPrivate': isPrivate,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully updated canvas privacy: $canvasId');
    } catch (e, stackTrace) {
      debugPrint('Error updating canvas privacy: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to update canvas privacy: ${e.message}');
      }
      rethrow;
    }
  }
}
